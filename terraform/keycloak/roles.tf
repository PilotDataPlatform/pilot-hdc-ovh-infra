# Built-in roles
data "keycloak_role" "offline_access" {
  realm_id = keycloak_realm.hdc.id
  name     = "offline_access"
}

data "keycloak_role" "uma_authorization" {
  realm_id = keycloak_realm.hdc.id
  name     = "uma_authorization"
}

data "keycloak_openid_client" "realm_management" {
  realm_id  = keycloak_realm.hdc.id
  client_id = "realm-management"
}

# Custom roles
resource "keycloak_role" "platform_admin" {
  realm_id    = keycloak_realm.hdc.id
  name        = "platform-admin"
  description = "Platform administrator"
  composite_roles = [
    data.keycloak_role.offline_access.id,
  ]
}

resource "keycloak_role" "admin_role" {
  realm_id    = keycloak_realm.hdc.id
  name        = "admin-role"
  description = "Admin role"
  composite_roles = [
    data.keycloak_role.offline_access.id,
  ]
}
