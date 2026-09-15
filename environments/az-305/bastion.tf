resource "azurerm_bastion_host" "lab" {
  name                = "az305-bastion"
  location            = azurerm_virtual_network.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  sku                = "Developer"
  virtual_network_id = azurerm_virtual_network.lab.id
}