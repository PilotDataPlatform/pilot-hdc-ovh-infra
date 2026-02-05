resource "kong_service" "this" {
  for_each = local.services

  name            = each.key
  protocol        = "http"
  host            = each.value.host
  port            = each.value.port
  path            = each.value.path
  retries         = 5
  connect_timeout = 60000
  write_timeout   = 60000
  read_timeout    = 60000
}
