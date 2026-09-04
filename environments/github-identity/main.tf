terraform {
  backend "azurerm" { use_azuread_auth = true }
}
variable "github_repository" {
  type        = string
  description = "Exact case-sensitive GitHub OWNER/REPO."
}
variable "state_storage_account_name" { type = string }
data "azurerm_resource_group" "customer" {
  name = "rg-summit-property-management-lab"
}
data "azurerm_storage_account" "state" {
  name                = var.state_storage_account_name
  resource_group_name = "rg-msp-lab-state"
}
resource "azurerm_resource_group" "identity" {
  name     = "rg-msp-lab-identity"
  location = data.azurerm_resource_group.customer.location
}
resource "azurerm_user_assigned_identity" "github" {
  name                = "id-summit-lab-github"
  location            = azurerm_resource_group.identity.location
  resource_group_name = azurerm_resource_group.identity.name
}
resource "azurerm_federated_identity_credential" "github" {
  name                = "github-summit-lab"
  resource_group_name = azurerm_resource_group.identity.name
  parent_id           = azurerm_user_assigned_identity.github.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_repository}:environment:summit-lab"
}
resource "azurerm_role_assignment" "customer" {
  scope                = data.azurerm_resource_group.customer.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}
resource "azurerm_role_assignment" "state" {
  scope                = "${data.azurerm_storage_account.state.id}/blobServices/default/containers/summit-property-management"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}
output "client_id" { value = azurerm_user_assigned_identity.github.client_id }
output "tenant_id" { value = azurerm_user_assigned_identity.github.tenant_id }

