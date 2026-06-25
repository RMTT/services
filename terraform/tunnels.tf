locals {
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

  tunnel_dns = merge([
    for name, t in local.cfg.tunnels : {
      for label, opts in t.routes : "${label}.${lookup(opts, "zone", t.default_zone)}" => {
        name    = label
        zone    = lookup(opts, "zone", t.default_zone)
        type    = "CNAME"
        content = "${data.sops_file.secrets.data["cf_tunnel_id_${name}"]}.cfargotunnel.com"
        ttl     = 1
        proxied = true
      }
    }
  ]...)
}

import {
  for_each = var.import ? local.tunnel_ids : {}

  to = cloudflare_zero_trust_tunnel_cloudflared_config.dynamic[each.key]
  id = "${data.sops_file.secrets.data["cf_account_id"]}/${each.value}"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "dynamic" {
  for_each = local.tunnel_ids

  account_id = data.sops_file.secrets.data["cf_account_id"]
  tunnel_id  = each.value

  config = {
    ingress = concat(local.tunnel_ingress[each.key], [{ service = "http_status:404" }])
  }
}
