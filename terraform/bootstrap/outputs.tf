output "s3_access_key_id" {
  value     = ovh_cloud_project_user_s3_credential.terraform_state.access_key_id
  sensitive = true
}

output "s3_secret_access_key" {
  value     = ovh_cloud_project_user_s3_credential.terraform_state.secret_access_key
  sensitive = true
}

output "bucket_name" {
  value = ovh_cloud_project_storage.tfstate.name
}

output "s3_endpoint" {
  value = "https://s3.${lower(var.s3_region)}.io.cloud.ovh.net"
}
