#C2 Public IP Setup
resource "random_string" "name" {
  length = 16
  upper = false
  number = false
  lower = true
  special = false
}

resource "azurerm_network_interface" "C2RDRNic" {
  name                = "${random_string.name.result}-C2RDR-Nic"
  location            = var.resourcegrouplocation
  resource_group_name = var.resourcegroupname

  ip_configuration {
    name                          = "C2RDRConfig"
    subnet_id                     = var.C2SubnetID
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.C2RDR.id
  }
  tags = {
    environment = "C2 Infra"
  }
}

resource "azurerm_public_ip" "C2RDR" {
  name                = "${random_string.name.result}-C2RDR-Public-IP"
  resource_group_name = var.resourcegroupname
  location            = var.resourcegrouplocation
  allocation_method   = "Static"
  domain_name_label   = "${random_string.name.result}c2rdr"
  reverse_fqdn = "{{ C2redirectordomain }}"
  tags = {
    environment = "C2 Infra"
  }
}

resource "azurerm_linux_virtual_machine" "C2RDR" {
  name                  = "${random_string.name.result}-C2RDR-VM"
  location              = var.resourcegrouplocation
  resource_group_name   = var.resourcegroupname
  network_interface_ids = [azurerm_network_interface.C2RDRNic.id]
  size                  = "Standard_B1s"
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

resource "azurerm_dns_a_record" "C2RDR" {
  name                = "@"
  zone_name           = var.C2DNS
  resource_group_name = var.resourcegroupname
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.C2RDR.id
  tags = {
    environment = "C2 Infra"
  }
}

resource "azurerm_dns_a_record" "C2RDRWWW" {
  name                = "www"
  zone_name           = var.C2DNS
  resource_group_name = var.resourcegroupname
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.C2RDR.id
  tags = {
    environment = "C2 Infra"
  }
}
