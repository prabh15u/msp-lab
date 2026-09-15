resource "azurerm_resource_group" "lab" {
  name     = "rg-az305"
  location = "West US"
}

resource "azurerm_virtual_network" "lab" {
  name                = "az305-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
}

resource "azurerm_subnet" "web" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_interface" "web" {
  count               = 2
  name                = "web-vm-${count.index + 1}-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "web" {
  count               = 2
  name                = "web-vm-${count.index + 1}"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  size                = "Standard_B2s_v2"

  network_interface_ids = [
    azurerm_network_interface.web[count.index].id
  ]

  admin_username = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "<h1>AZ-305 Web Server ${count.index + 1}</h1>" > /var/www/html/index.html
    systemctl enable nginx
    systemctl restart nginx
  EOF
  )
}