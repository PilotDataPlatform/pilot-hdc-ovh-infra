terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "2.10.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
  }
}

provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}

provider "kubernetes" {
  host                   = ovh_cloud_project_kube.this["dev"].kubeconfig_attributes[0].host
  cluster_ca_certificate = base64decode(ovh_cloud_project_kube.this["dev"].kubeconfig_attributes[0].cluster_ca_certificate)
  client_certificate     = base64decode(ovh_cloud_project_kube.this["dev"].kubeconfig_attributes[0].client_certificate)
  client_key             = base64decode(ovh_cloud_project_kube.this["dev"].kubeconfig_attributes[0].client_key)
}
