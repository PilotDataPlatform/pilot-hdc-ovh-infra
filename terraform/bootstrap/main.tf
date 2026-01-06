resource "ovh_cloud_project_user" "terraform_state" {
  service_name = var.ovh_project_id
  description  = "Terraform state backend access"
  role_names   = ["objectstore_operator"]
}

resource "ovh_cloud_project_storage" "tfstate" {
  service_name = var.ovh_project_id
  region_name  = var.s3_region
  name         = "pilot-hdc-tfstate"

  versioning = {
    status = "enabled"
  }

  encryption = {
    sse_algorithm = "AES256"
  }
}

resource "ovh_cloud_project_user_s3_credential" "terraform_state" {
  service_name = var.ovh_project_id
  user_id      = ovh_cloud_project_user.terraform_state.id
}

resource "ovh_cloud_project_user_s3_policy" "terraform_state" {
  service_name = var.ovh_project_id
  user_id      = ovh_cloud_project_user.terraform_state.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "TerraformStateAccess"
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ]
      Resource = [
        "arn:aws:s3:::${ovh_cloud_project_storage.tfstate.name}",
        "arn:aws:s3:::${ovh_cloud_project_storage.tfstate.name}/*"
      ]
    }]
  })
}
