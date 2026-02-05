variable "env" {
  type        = string
  description = "Environment (dev or prod)"

  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "env must be dev or prod"
  }
}

variable "kong_admin_uri" {
  type        = string
  default     = "http://localhost:8001"
  description = "Kong Admin API URI (via kubectl port-forward)"
}

variable "oidc_discovery" {
  type        = string
  description = "Keycloak OIDC discovery URL"
}

variable "oidc_introspection_endpoint" {
  type        = string
  description = "Keycloak token introspection endpoint"
}

variable "oidc_client_secret" {
  type        = string
  sensitive   = true
  description = "Kong OIDC client secret (from keycloak output)"
}

variable "cors_origins" {
  type        = list(string)
  default     = ["*"]
  description = "CORS allowed origins"
}
