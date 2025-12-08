# Managed K8s cluster (dev only)
resource "ovh_cloud_project_kube" "this" {
  for_each = { for k, v in local.environments : k => v if k == "dev" }

  service_name = var.ovh_project_id
  name         = "hdc-${each.key}"
  region       = var.region

  private_network_id = tolist(
    ovh_cloud_project_network_private.this[each.key].regions_attributes
  )[0].openstackid

  nodes_subnet_id = ovh_cloud_project_network_private_subnet.this[each.key].id

  private_network_configuration {
    # Empty gateway = nodes get public IPs for egress (multiple egress IPs)
    # Set to router IP for single egress IP (useful for external service whitelisting)
    default_vrack_gateway              = ""
    private_network_routing_as_default = true
  }

  depends_on = [ovh_cloud_project_gateway.this]

  timeouts {
    create = "20m"
  }
}

# Node pool
resource "ovh_cloud_project_kube_nodepool" "default" {
  for_each = ovh_cloud_project_kube.this

  service_name  = var.ovh_project_id
  kube_id       = each.value.id
  name          = "default-pool"
  flavor_name   = var.kube_node_flavor
  desired_nodes = var.kube_node_count

  timeouts {
    create = "20m"
  }
}

output "kube_cluster_id" {
  value = { for k, v in ovh_cloud_project_kube.this : k => v.id }
}

output "kubeconfig" {
  value     = { for k, v in ovh_cloud_project_kube.this : k => v.kubeconfig }
  sensitive = true
}
