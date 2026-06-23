locals {
  cfg = nonsensitive(yamldecode(file("config.yaml")))

  zone_lookup = {
    "rmtt.tech" = data.sops_file.secrets.data["cf_zone_rmtt_tech"]
    "rmtt.host" = data.sops_file.secrets.data["cf_zone_rmtt_host"]
  }

  cf_ids = yamldecode(file(var.cf_record_id_file))

  default_origin_request = {
    connect_timeout = 10
    http2_origin    = true
    no_tls_verify   = true
  }

  # tunnel id per tunnel name, from secret cf_tunnel_id_<name>
  tunnel_ids = {
    for name in keys(local.cfg.tunnels) :
    name => data.sops_file.secrets.data["cf_tunnel_id_${name}"]
  }

  # all tunnel services flattened across tunnels -> {fqdn => entry}
  tunnel_ingress = {
    for name, t in local.cfg.tunnels :
    "${name}" => [
      for label, opts in t.routes : {
        hostname = "${label}.${lookup(opts, "zone", t.default_zone)}"
        service  = lookup(opts, "service", t.default_service)
        origin_request = merge(local.default_origin_request, {
          http_host_header = "${label}.${lookup(opts, "zone", t.default_zone)}"
        })
      }
    ]
  }

  tunnel_dns = merge(flatten([
    for name, t in local.cfg.tunnels : [
      for label, opts in t.routes : {
        "${label}.${lookup(opts, "zone", t.default_zone)}" = {
          name      = label
          zone      = lookup(opts, "zone", t.default_zone)
          dns_value = "${data.sops_file.secrets.data["cf_tunnel_id_${name}"]}.cfargotunnel.com"
        }
      }
    ]
  ])...)

  # public host A records -> cloudflare A + adguard
  public_dns = merge(flatten([
    for zone, entries in local.cfg.hosts.public : [
      for label, ip in entries : {
        "${label}.${zone}" = { name = label, zone = zone, dns_value = ip }
      }
    ]
  ])...)

  # LAN-only -> adguard only
  private_dns = merge(flatten([
    for zone, entries in local.cfg.hosts.private : [
      for label, ip in entries : {
        "${label}.${zone}" = { name = label, zone = zone, dns_value = ip }
      }
    ]
  ])...)

  adguard_dns = merge(local.public_dns, local.private_dns)

  import_tunnel_dns = {
    for k, v in local.tunnel_dns : k => v
    if contains(keys(local.cf_ids), k)
  }
  import_public_dns = {
    for k, v in local.public_dns : k => v
    if contains(keys(local.cf_ids), k)
  }
}

# just overwrite dns value for adguard
resource "adguard_rewrite" "dynamic" {
  for_each = local.adguard_dns

  domain = each.key
  answer = each.value.dns_value
}

import {
  for_each = local.import_public_dns

  to = cloudflare_dns_record.dynamic[each.key]
  id = "${local.zone_lookup[each.value.zone]}/${local.cf_ids[each.key]}"
}

import {
  for_each = local.import_tunnel_dns

  to = cloudflare_dns_record.tunnel[each.key]
  id = "${local.zone_lookup[each.value.zone]}/${local.cf_ids[each.key]}"
}

resource "cloudflare_dns_record" "dynamic" {
  for_each = local.public_dns

  zone_id = local.zone_lookup[each.value.zone]
  name    = each.value.name
  content = each.value.dns_value
  type    = "A"
  ttl     = 1
  comment = "records created by terraform"
}

resource "cloudflare_dns_record" "tunnel" {
  for_each = local.tunnel_dns

  zone_id = local.zone_lookup[each.value.zone]
  name    = each.value.name
  content = each.value.dns_value
  type    = "CNAME"
  ttl     = 1
  proxied = true
  comment = "tunnel cname managed by terraform"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "dynamic" {
  for_each = local.tunnel_ids

  account_id = data.sops_file.secrets.data["cf_account_id"]
  tunnel_id  = each.value

  config = {
    ingress = concat(local.tunnel_ingress[each.key], [{ service = "http_status:404" }])
  }
}
