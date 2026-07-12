terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.4"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.4.1"
    }
  }
}

data "sops_file" "secrets" {
  source_file = "./secrets/keys.yaml"

  lifecycle {
    precondition {
      condition     = var.import || (fileexists("${path.module}/terraform.tfstate") && file("${path.module}/terraform.tfstate") != "")
      error_message = "If there is no tfstate file, run `terraform plan -var import=true` first"
    }
  }
}

provider "cloudflare" {
  api_token = data.sops_file.secrets.data["CLOUDFLARE_API_TOKEN"]
}

provider "dns" {
  update {
    server        = "oracle.infra.rmtt.host"
    key_name      = "terraform-key."
    key_algorithm = "hmac-sha256"
    key_secret    = data.sops_file.secrets.data["bind_terraform_key"]
  }
}
