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
    "pilot-upload-gr" = {
      host       = "upload.greenroom"
      port       = 5079
      path       = null
      route_path = "/pilot/upload/gr"
      methods    = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
      oidc       = true
      cors       = true
      timeout    = 180000
    }
    "pilot-download-gr" = {
      host       = "download.greenroom"
      port       = 5077
      path       = null
      route_path = "/pilot/portal/download/gr"
      methods    = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
      oidc       = false
      cors       = true
    }
    "pilot-download-core" = {
      host       = "download.core"
      port       = 5077
      path       = null
      route_path = "/pilot/portal/download/core"
      methods    = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
      oidc       = false
      cors       = true
    }
    "pilot-cli-bff-api" = {
      host       = "bff-cli.utility"
      port       = 5080
      path       = null
      route_path = "/pilot/cli"
      methods    = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
      oidc       = true
      cors       = false
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
