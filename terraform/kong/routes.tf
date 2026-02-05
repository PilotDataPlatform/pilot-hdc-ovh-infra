resource "kong_route" "this" {
  for_each = local.services

  name                       = each.key
  protocols                  = ["http", "https"]
  methods                    = each.value.methods
  paths                      = [each.value.route_path]
  path_handling              = "v1"
  https_redirect_status_code = 426
  strip_path                 = true
  preserve_host              = false
  regex_priority             = 0
  service_id                 = kong_service.this[each.key].id
}
