variable "customer" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "address_space" { type = list(string) }
variable "subnets" {
  type        = map(string)
  description = "Subnet name to IPv4 CIDR; ranges must fit the VNet and not overlap."
}
variable "tags" {
  type    = map(string)
  default = {}
}
locals {
  prefix = "${var.customer}-${var.environment}"
  tags   = merge(var.tags, { customer = var.customer, environment = var.environment, managed_by = "opentofu" })
}
resource "azurerm_resource_group" "this" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = local.tags
}
resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.address_space
  tags                = local.tags
}
resource "azurerm_subnet" "this" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value]
}
resource "azurerm_network_security_group" "this" {
  for_each            = var.subnets
  name                = "nsg-${local.prefix}-${each.key}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = var.subnets
  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
output "resource_group_id" { value = azurerm_resource_group.this.id }
output "resource_group_name" { value = azurerm_resource_group.this.name }
output "virtual_network_id" { value = azurerm_virtual_network.this.id }
output "subnet_ids" { value = { for k, v in azurerm_subnet.this : k => v.id } }

