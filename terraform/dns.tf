locals {
  zone_lookup = {
    "rmtt.tech" = data.sops_file.secrets.data["cf_zone_rmtt_tech"]
    "rmtt.host" = data.sops_file.secrets.data["cf_zone_rmtt_host"]
  }

  # public host A records -> cloudflare A + bind9
  public_dns = merge([
    for zone, entries in local.cfg.hosts.public : {
      for label, ip in entries : "${label}.${zone}" => {
        name    = label
        zone    = zone
        type    = "A"
        content = ip
        ttl     = 1
        proxied = false
      }
    }
  ]...)

  # All DNS records defined in config
  config_cf_dns = merge(local.public_dns, local.tunnel_dns)


  # LAN Only
  private_dns_records = merge(
    {
      for fqdn, r in local.public_dns : fqdn => {
        name      = r.name
        zone      = "${r.zone}."
        addresses = [r.content]
      }
    },
    merge([
      for zone, entries in local.cfg.hosts.private : {
        for label, ip in entries : "${label}.${zone}" => {
          name      = label
          zone      = "${zone}."
          addresses = [ip]
        }
      }
    ]...)
  )
}

# DNS A records using dns provider
resource "dns_a_record_set" "dynamic" {
  for_each = local.private_dns_records

  zone      = each.value.zone
  name      = each.value.name
  addresses = each.value.addresses
  ttl       = 300
}

resource "cloudflare_dns_record" "dynamic" {
  for_each = local.config_cf_dns

  zone_id = local.zone_lookup[each.value.zone]
  name    = each.key
  content = each.value.content
  type    = each.value.type
  ttl     = each.value.ttl
  proxied = each.value.proxied
  comment = "managed and configured by terraform"
}
