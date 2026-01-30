output "realm_id" {
  value = keycloak_realm.hdc.id
}

output "react_app_client_id" {
  value = keycloak_openid_client.react_app.client_id
}

output "kong_client_id" {
  value = keycloak_openid_client.kong.client_id
}

output "kong_client_secret" {
  value     = keycloak_openid_client.kong.client_secret
  sensitive = true
}
