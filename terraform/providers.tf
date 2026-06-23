terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
    adguard = {
      source  = "gmichels/adguard"
      version = "~> 1.7.0"
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

provider "adguard" {
  host     = "homerouter.java-crocodile.ts.net:3000"
  username = data.sops_file.secrets.data["adguard_username"]
  password = data.sops_file.secrets.data["adguard_password"]
  scheme   = "http"
  insecure = false
}
