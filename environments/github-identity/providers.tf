provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}
variable "subscription_id" {
  type        = string
  description = "Azure subscription UUID."
}
provider "azuread" {
  tenant_id = var.tenant_id
}

variable "tenant_id" {
  type = string
}
