#C2 Public IP Setup
resource "random_string" "name" {
  length = 16
  upper = false
  number = false
  lower = true
  special = false
}

resource "azurerm_network_interface" "C2" {
  name                = "${random_string.name.result}-C2-Nic"
  location            = var.resourcegrouplocation
  resource_group_name = var.resourcegroupname

  ip_configuration {
    name                          = "C2Config"
    subnet_id                     = var.C2SubnetID
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.C2.id
  }
  tags = {
    environment = "C2 Infra"
  }
}

resource "azurerm_public_ip" "C2" {
  name                = "${random_string.name.result}-C2-Public-IP"
  resource_group_name = var.resourcegroupname
  location            = var.resourcegrouplocation
  allocation_method   = "Static"
  domain_name_label   = "${random_string.name.result}c2"
  tags = {
    environment = "C2 Infra"
  }
}

resource "azurerm_linux_virtual_machine" "C2" {
  name                  = "${random_string.name.result}-C2-VM"
  location              = var.resourcegrouplocation
  resource_group_name   = var.resourcegroupname
  network_interface_ids = [azurerm_network_interface.C2.id]
  size                  = "Standard_B2s"
  admin_username        = var.adminaccount

  disable_password_authentication = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.adminaccount
    public_key = file("${var.publickey}")
  }
  tags = {
    environment = "C2 Infra"
  }
}
