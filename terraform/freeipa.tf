resource "ovh_cloud_project_instance" "freeipa" {
  count          = var.deploy_freeipa ? 1 : 0
  service_name   = var.ovh_project_id
  region         = var.region
  billing_period = "hourly"
  name           = "freeipa-${var.env}"

  boot_from {
    image_id = var.instance_image_id
  }

  flavor {
    flavor_id = var.instance_flavor_id
  }

  ssh_key {
    name = var.ssh_key_name
  }

  user_data = <<-EOF
    #!/bin/bash
    systemctl enable --now ssh.socket
  EOF

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

resource "ovh_cloud_project_volume" "freeipa" {
  count        = var.deploy_freeipa ? 1 : 0
  service_name = var.ovh_project_id
  region_name  = var.region
  name         = "freeipa-data-${var.env}"
  description  = "FreeIPA data volume for ${var.env}"
  size         = var.freeipa_volume_size
  type         = "classic"
}

output "freeipa_addresses" {
  value = var.deploy_freeipa ? ovh_cloud_project_instance.freeipa[0].addresses : []
}

output "freeipa_volume_id" {
  value = var.deploy_freeipa ? ovh_cloud_project_volume.freeipa[0].id : ""
}
