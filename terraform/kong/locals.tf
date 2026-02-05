# Service and route definitions

locals {
  services = {
    "pilot-portal-api" = {
      host       = "bff.utility"
      port       = 5060
      path       = null
      route_path = "/pilot/portal"
      methods    = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
      oidc       = true
      cors       = true
    }
    "pilot-user-auth" = {
      host       = "auth.utility"
      port       = 5061
      path       = "/v1/users/auth"
      route_path = "/pilot/portal/users/auth"
      methods    = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
      oidc       = false
      cors       = true
    }
    "pilot-user-auth-refresh" = {
      host       = "auth.utility"
      port       = 5061
      path       = "/v1/users/refresh"
      route_path = "/pilot/portal/users/refresh"
      methods    = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
      oidc       = false
      cors       = true
    }
    "dataops-task-stream" = {
      host       = "dataops.utility"
      port       = 5063
      path       = "/v1/task-stream"
      route_path = "/pilot/task-stream"
      methods    = ["GET"]
      oidc       = false
      cors       = false
    }
  }

  # Filtered maps for plugins
  oidc_services = { for k, v in local.services : k => v if v.oidc }
  cors_services = { for k, v in local.services : k => v if v.cors }
}
