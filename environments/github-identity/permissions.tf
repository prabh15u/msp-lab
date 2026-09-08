variable "state_resource_group_name" {
  type    = string
  default = "rg-msp-lab-state"
}

variable "state_storage_account_name" {
  type    = string
  default = "tfstateprabh"
}

variable "customer_state_container" {
  type    = string
  default = "summit-property-management"
}

variable "customer_resource_group_name" {
  type = string
}

locals {
  customer_state_scope = "/subscriptions/${var.subscription_id}/resourceGroups/${var.state_resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.state_storage_account_name}/blobServices/default/containers/${var.customer_state_container}"
}

data "azurerm_resource_group" "customer" {
  name = var.customer_resource_group_name
}

resource "azurerm_role_assignment" "github_customer_state" {
  scope                = local.customer_state_scope
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.github_identity.principal_id
  principal_type       = "ServicePrincipal"
}
resource "azurerm_role_assignment" "github_customer_reader" {
  scope                = data.azurerm_resource_group.customer.id
  role_definition_name = "Reader"
  principal_id         = module.github_identity.principal_id
  principal_type       = "ServicePrincipal"
}