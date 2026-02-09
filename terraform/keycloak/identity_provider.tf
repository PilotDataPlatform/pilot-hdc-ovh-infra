resource "keycloak_oidc_identity_provider" "ebrains" {
  realm                         = keycloak_realm.hdc.id
  alias                         = "ebrains-keycloak"
  display_name                  = "EBRAINS"
  provider_id                   = "keycloak-oidc"
  enabled                       = true
  trust_email                   = false
  store_token                   = true
  add_read_token_role_on_create = true
  first_broker_login_flow_alias = "first broker login"
  sync_mode                     = "IMPORT"
  login_hint                    = true

  client_id     = var.ebrains_oidc_client_id
  client_secret = var.ebrains_oidc_client_secret

  # EBRAINS IAM OIDC endpoints (realm: hbp)
  authorization_url = "https://iam.ebrains.eu/auth/realms/hbp/protocol/openid-connect/auth"
  token_url         = "https://iam.ebrains.eu/auth/realms/hbp/protocol/openid-connect/token"

  default_scopes = "openid profile team group email clb.wiki.read clb.wiki.write roles"

  extra_config = {
    "clientAuthMethod" = "client_secret_basic"
    "prompt"           = "login"
  }
}
