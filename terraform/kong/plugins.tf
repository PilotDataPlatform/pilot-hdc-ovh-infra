# OIDC plugin — validates bearer tokens via Keycloak introspection
resource "kong_plugin" "oidc" {
  for_each = local.oidc_services

  name     = "oidc"
  route_id = kong_route.this[each.key].id
  enabled  = true

  config_json = jsonencode({
    introspection_endpoint_auth_method = null
    redirect_uri_path                  = null
    response_type                      = "code"
    token_endpoint_auth_method         = "client_secret_post"
    logout_path                        = "/logout"
    redirect_after_logout_uri          = "/"
    ssl_verify                         = "yes"
    session_secret                     = null
    introspection_endpoint             = var.oidc_introspection_endpoint
    recovery_page_path                 = null
    filters                            = null
    client_id                          = "kong"
    realm                              = "kong"
    discovery                          = var.oidc_discovery
    bearer_only                        = "yes"
    client_secret                      = var.oidc_client_secret
    scope                              = "openid"
  })
}

# CORS plugin
resource "kong_plugin" "cors" {
  for_each = local.cors_services

  name     = "cors"
  route_id = kong_route.this[each.key].id
  enabled  = true

  config_json = jsonencode({
    preflight_continue = false
    credentials        = false
    headers            = null
    methods            = each.value.methods
    exposed_headers    = null
    origins            = var.cors_origins
    max_age            = null
  })
}
