variable "location" {
  type    = string
  default = "westus2"
}
variable "storage_account_name" {
  type        = string
  description = "Globally unique, 3–24 lowercase letters/numbers."
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Use 3–24 lowercase letters or numbers."
  }
}
variable "operator_object_id" {
  type        = string
  description = "Object ID of the human running the bootstrap; not application/client ID."
}
resource "azurerm_resource_group" "state" {
  name     = "rg-msp-lab-state"
  location = var.location
  tags     = { managed_by = "opentofu", purpose = "msp-lab-state" }
}
resource "azurerm_storage_account" "state" {
  name                = var.storage_account_name
  resource_group_name = azurerm_resource_group.state.name
  location            = azurerm_resource_group.state.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true

  blob_properties {
    versioning_enabled = true
    delete_retention_policy { days = 7 }
    container_delete_retention_policy { days = 7 }
  }

  tags = azurerm_resource_group.state.tags
  lifecycle { prevent_destroy = true }
}

resource "azurerm_storage_container" "state" {
  for_each              = toset(["platform", "summit-property-management"])
  name                  = each.key
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "operator_state" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.operator_object_id
}

output "storage_account_name" { value = azurerm_storage_account.state.name }
output "resource_group_name" { value = azurerm_resource_group.state.name }
output "storage_account_id" { value = azurerm_storage_account.state.id }

