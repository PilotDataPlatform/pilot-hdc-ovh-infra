output "service_ids" {
  value       = { for k, v in kong_service.this : k => v.id }
  description = "Kong service IDs"
}

output "route_ids" {
  value       = { for k, v in kong_route.this : k => v.id }
  description = "Kong route IDs"
}

output "routes_configured" {
  value       = keys(kong_route.this)
  description = "List of configured route names"
}
