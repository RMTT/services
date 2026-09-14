terraform {
  cloud {
    organization = "rmtt-tech"

    workspaces {
      name = "terraform"
    }
  }

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
}

provider "cloudflare" {
  api_token = data.sops_file.secrets.data["CLOUDFLARE_API_TOKEN"]
}

provider "dns" {
  update {
    server        = "oracle.infra.rmtt.host"
    timeout       = "5s"
    key_name      = "terraform-key."
    key_algorithm = "hmac-sha256"
    key_secret    = data.sops_file.secrets.data["bind_terraform_key"]
  }
}
