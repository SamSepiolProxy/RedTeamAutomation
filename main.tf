# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "ResourceGroup" {
  name     = var.resourcename
  location = "uksouth"

  tags = {
    name = "Red Team Infra"
  }
}


#C2 Redirector DNS
resource "azurerm_dns_zone" "C2DNS" {
  name                = var.c2_redirector_domain
  resource_group_name = azurerm_resource_group.ResourceGroup.name
}

resource "azurerm_virtual_network" "MainNetwork" {
  name                = "RedTeamNetwork"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.ResourceGroup.location
  resource_group_name = azurerm_resource_group.ResourceGroup.name
  tags = {
    environment = "Red Team Infra"
  }
}

module "C2Network" {
  source                = "./modules/Network"
  resourcegrouplocation = azurerm_resource_group.ResourceGroup.location
  resourcegroupname     = azurerm_resource_group.ResourceGroup.name
  virtualnetworkname    = azurerm_virtual_network.MainNetwork.name
  ipwhitelist           = var.ip_whitelist
  C2RDRPrivateIP        = module.C2_RDR.C2_RDR_Private_IP
  C2PrivateIP           = module.C2_Cov.C2_Private_IP
}


module "C2_Cov" {
  source                = "./modules/C2"
  resourcegrouplocation = azurerm_resource_group.ResourceGroup.location
  resourcegroupname     = azurerm_resource_group.ResourceGroup.name
  adminaccount          = var.adminaccountusername
  publickey             = var.public_key
  C2SubnetID            = module.C2Network.C2_Subnet_ID
}

module "C2_RDR" {
  source                = "./modules/C2RDR"
  resourcegrouplocation = azurerm_resource_group.ResourceGroup.location
  resourcegroupname     = azurerm_resource_group.ResourceGroup.name
  adminaccount          = var.adminaccountusername
  publickey             = var.public_key
  C2SubnetID            = module.C2Network.C2_Subnet_ID
  C2DNS                 = azurerm_dns_zone.C2DNS.name
}