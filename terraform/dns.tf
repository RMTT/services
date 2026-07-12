locals {
  zone_lookup = {
    "rmtt.tech" = data.sops_file.secrets.data["cf_zone_rmtt_tech"]
    "rmtt.host" = data.sops_file.secrets.data["cf_zone_rmtt_host"]
  }

  # public host A records -> cloudflare A + adguard
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

  # Extract all records from the cloudflare data source
  cloudflare_existing_records = merge([
    for zone_name, ds in data.cloudflare_dns_records.all_dns_records : {
      for record in ds.result : record.name => {
        name    = record.name
        zone    = zone_name
        type    = record.type
        content = record.content
        ttl     = record.ttl
        proxied = record.proxied
        id      = record.id
      }
    }
  ]...)

  # LAN Only
  dns_records = merge(
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

import {
  for_each = var.import ? local.dns_records : {}

  to = dns_a_record_set.dynamic[each.key]
  id = "${each.key}."
}

# DNS A records using dns provider
resource "dns_a_record_set" "dynamic" {
  for_each = local.dns_records

  zone      = each.value.zone
  name      = each.value.name
  addresses = each.value.addresses
  ttl       = 300
}

data "cloudflare_dns_records" "all_dns_records" {
  for_each = local.zone_lookup

  zone_id = each.value
}

import {
  for_each = var.import ? {
    for fqdn, record in local.cloudflare_existing_records : fqdn => record
  } : {}

  to = cloudflare_dns_record.dynamic[each.key]
  id = "${local.zone_lookup[each.value.zone]}/${each.value.id}"
}

resource "cloudflare_dns_record" "dynamic" {
  for_each = var.import ? local.cloudflare_existing_records : local.config_cf_dns

  zone_id = local.zone_lookup[each.value.zone]
  name    = each.value.name
  content = each.value.content
  type    = each.value.type
  ttl     = each.value.ttl
  proxied = each.value.proxied
  comment = "managed and configured by terraform"
}
