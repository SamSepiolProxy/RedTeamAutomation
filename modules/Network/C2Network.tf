#Resource Group Subnet C2
resource "random_string" "name" {
  length = 16
  upper = false
  number = false
  lower = true
  special = false
}

resource "azurerm_subnet" "C2Subnet" {
  name                 = "${random_string.name.result}-C2-Subnet"
  resource_group_name  = var.resourcegroupname
  virtual_network_name = var.virtualnetworkname
  address_prefixes     = ["10.10.0.0/24"]
}

resource "azurerm_network_security_group" "C2NSG" {
  name                = "${random_string.name.result}-C2-NSG"
  location            = var.resourcegrouplocation
  resource_group_name = var.resourcegroupname

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = ["${var.ipwhitelist}"]
    destination_address_prefix = "*"
  }
  security_rule {
    name                         = "HTTP-Private"
    priority                     = 101
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "TCP"
    source_port_range            = "*"
    destination_port_range       = "80"
    source_address_prefix        = "*"
    destination_address_prefixes = ["${var.C2RDRPrivateIP}"]
  }
  security_rule {
    name                         = "HTTPS-Private"
    priority                     = 102
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "TCP"
    source_port_range            = "*"
    destination_port_range       = "443"
    source_address_prefix        = "*"
    destination_address_prefixes = ["${var.C2RDRPrivateIP}"]
  }
  security_rule {
    name                         = "Cov-Test"
    priority                     = 103
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "TCP"
    source_port_range            = "*"
    destination_port_range       = "7443"
    source_address_prefixes        = ["${var.ipwhitelist}"]
    destination_address_prefixes = ["${var.C2PrivateIP}"]
  }
  tags = {
    environment = "C2 Infra"
  }

}

resource "azurerm_subnet_network_security_group_association" "C2Infra" {
  subnet_id                 = azurerm_subnet.C2Subnet.id
  network_security_group_id = azurerm_network_security_group.C2NSG.id
}