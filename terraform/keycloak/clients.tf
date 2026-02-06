# react-app — public SPA client
resource "keycloak_openid_client" "react_app" {
  realm_id  = keycloak_realm.hdc.id
  client_id = "react-app"
  name      = "react-app"
  enabled   = true

  access_type                  = "PUBLIC"
  standard_flow_enabled        = true
  direct_access_grants_enabled = var.enable_direct_grants
  implicit_flow_enabled        = false

  valid_redirect_uris = ["https://${var.domain}/*"]
  web_origins         = ["https://${var.domain}"]
  base_url            = "https://${var.domain}"
}

resource "keycloak_openid_client_default_scopes" "react_app" {
  realm_id  = keycloak_realm.hdc.id
  client_id = keycloak_openid_client.react_app.id

  default_scopes = [
    "profile",
    "email",
    "roles",
    "web-origins",
    keycloak_openid_client_scope.groups.name,
    keycloak_openid_client_scope.openid.name,
  ]
}

# Protocol mappers on react-app client

resource "keycloak_openid_user_attribute_protocol_mapper" "minio_policy" {
  realm_id  = keycloak_realm.hdc.id
  client_id = keycloak_openid_client.react_app.id
  name      = "minio_policy_mapper"

  user_attribute      = "policy"
  claim_name          = "policy"
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
  claim_value_type    = "String"
  multivalued         = false
}

resource "keycloak_openid_audience_protocol_mapper" "minio_aud" {
  realm_id  = keycloak_realm.hdc.id
  client_id = keycloak_openid_client.react_app.id
  name      = "aud_mapper"

  included_custom_audience = "minio"
  add_to_id_token          = false
  add_to_access_token      = true
}

resource "keycloak_openid_user_session_note_protocol_mapper" "client_id" {
  realm_id  = keycloak_realm.hdc.id
  client_id = keycloak_openid_client.react_app.id
  name      = "Client ID"

  session_note     = "clientId"
  claim_name       = "clientId"
  claim_value_type = "String"
}

resource "keycloak_openid_user_session_note_protocol_mapper" "client_ip" {
  realm_id  = keycloak_realm.hdc.id
  client_id = keycloak_openid_client.react_app.id
  name      = "Client IP Address"

  session_note     = "clientAddress"
  claim_name       = "clientAddress"
  claim_value_type = "String"
}

resource "keycloak_openid_user_session_note_protocol_mapper" "client_host" {
  realm_id  = keycloak_realm.hdc.id
  client_id = keycloak_openid_client.react_app.id
  name      = "Client Host"

  session_note     = "clientHost"
  claim_name       = "clientHost"
  claim_value_type = "String"
}

# --- Kong API Gateway client (confidential) ---
# Used by auth service for Keycloak user management
# and by Kong for OIDC token introspection
resource "keycloak_openid_client" "kong" {
  realm_id  = keycloak_realm.hdc.id
  client_id = "kong"
  name      = "Kong API Gateway"
  enabled   = true

  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  service_accounts_enabled     = true

  root_url            = "https://api.${var.domain}"
  valid_redirect_uris = ["https://api.${var.domain}/*"]
  web_origins         = ["https://api.${var.domain}"]
}

# Kong protocol mappers

resource "keycloak_openid_audience_protocol_mapper" "kong_aud_mapper" {
  realm_id  = keycloak_realm.hdc.id
  client_id = keycloak_openid_client.kong.id
  name      = "aud_mapper"

  included_custom_audience = "minio"
  add_to_id_token          = false
}

resource "keycloak_openid_user_attribute_protocol_mapper" "kong_minio_policy" {
  realm_id  = keycloak_realm.hdc.id
  client_id = keycloak_openid_client.kong.id
  name      = "minio_policy_mapper"

  user_attribute   = "policy"
  claim_name       = "policy"
  claim_value_type = "String"
}

resource "keycloak_openid_user_property_protocol_mapper" "kong_username_sub" {
  realm_id  = keycloak_realm.hdc.id
  client_id = keycloak_openid_client.kong.id
  name      = "user-property-mapper"

  user_property    = "username"
  claim_name       = "sub"
  claim_value_type = "String"
}

# Kong service account roles

resource "keycloak_openid_client_service_account_realm_role" "kong_offline_access" {
  realm_id                = keycloak_realm.hdc.id
  service_account_user_id = keycloak_openid_client.kong.service_account_user_id
  role                    = data.keycloak_role.offline_access.name
}

resource "keycloak_openid_client_service_account_realm_role" "kong_uma_authorization" {
  realm_id                = keycloak_realm.hdc.id
  service_account_user_id = keycloak_openid_client.kong.service_account_user_id
  role                    = data.keycloak_role.uma_authorization.name
}

resource "keycloak_openid_client_service_account_role" "kong_manage_realm" {
  realm_id                = keycloak_realm.hdc.id
  service_account_user_id = keycloak_openid_client.kong.service_account_user_id
  client_id               = data.keycloak_openid_client.realm_management.id
  role                    = "manage-realm"
}

resource "keycloak_openid_client_service_account_role" "kong_manage_users" {
  realm_id                = keycloak_realm.hdc.id
  service_account_user_id = keycloak_openid_client.kong.service_account_user_id
  client_id               = data.keycloak_openid_client.realm_management.id
  role                    = "manage-users"
}
