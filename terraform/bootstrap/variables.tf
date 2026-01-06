variable "ovh_application_key" {
  type      = string
  sensitive = true
}

variable "ovh_application_secret" {
  type      = string
  sensitive = true
}

variable "ovh_consumer_key" {
  type      = string
  sensitive = true
}

variable "ovh_project_id" {
  type      = string
  sensitive = true
}

variable "s3_region" {
  type        = string
  default     = "DE"
  description = "OVH S3 region (DE, GRA, SBG, etc.)"
}
