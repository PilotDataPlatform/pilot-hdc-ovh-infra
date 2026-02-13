resource "ovh_cloud_project_instance" "nfs" {
  count          = var.deploy_nfs ? 1 : 0
  service_name   = var.ovh_project_id
  region         = var.region
  billing_period = "hourly"
  name           = "nfs-${var.env}"

  boot_from {
    image_id = var.instance_image_id
  }

  flavor {
    flavor_id = var.instance_flavor_id
  }

  ssh_key {
    name = var.ssh_key_name
  }

  network {
    private {
      network {
        id        = ovh_cloud_project_network_private.this.regions_openstack_ids[var.region]
        subnet_id = ovh_cloud_project_network_private_subnet.this.id
      }
      gateway {
        id = ovh_cloud_project_gateway.this.id
      }
    }
  }
}

resource "ovh_cloud_project_volume" "nfs" {
  count        = var.deploy_nfs ? 1 : 0
  service_name = var.ovh_project_id
  region_name  = var.region
  name         = "nfs-data-${var.env}"
  description  = "NFS export volume for ${var.env}"
  size         = var.nfs_volume_size
  type         = "classic"
}

output "nfs_addresses" {
  value = var.deploy_nfs ? ovh_cloud_project_instance.nfs[0].addresses : []
}

output "nfs_volume_id" {
  value = var.deploy_nfs ? ovh_cloud_project_volume.nfs[0].id : ""
}
