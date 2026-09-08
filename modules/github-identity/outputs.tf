output "client_id" {
  value = azuread_application.github.client_id
}

output "principal_id" {
  value = azuread_service_principal.github.object_id
}