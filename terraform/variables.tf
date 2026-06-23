variable "cf_record_id_file" {
  type    = string
  default = "./cf_ids.yaml"

  validation {
    condition     = fileexists(var.cf_record_id_file)
    error_message = "cannot find ./cf_ids.yaml, please create it via 'sops exec-env ./secrets/keys.yaml cf-record-ids'"
  }
}
