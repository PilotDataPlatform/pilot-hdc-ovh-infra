terraform {
  required_version = "~> 1.5.0"

  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "2.10.0"
    }
  }
}

provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}
