terraform {
  required_version = ">= 1.5"

  backend "s3" {} # Config via -backend-config

  required_providers {
    kong = {
      source  = "kevholditch/kong"
      version = "6.5.0"
    }
  }
}

provider "kong" {
  kong_admin_uri = var.kong_admin_uri
}
