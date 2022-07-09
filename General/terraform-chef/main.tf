provider "azurerm" {
  features {}
  skip_provider_registration = true
}


terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      version = "~> 2.0"
      source  = "hashicorp/azurerm"
    }
  }
  backend "azurerm" {
    resource_group_name  = "ProdFC-Shared"
    storage_account_name = "examplefcsterraform"
    container_name       = "fc-s"
    key                  = "prodfc-s-chef.tfstate"
  }
}

module "settings" {
  source = "../settings"
}

module "network" {
  source = "../data/network"
}

resource "azurerm_public_ip" "CHEF01_public_ip" {
  name                = "${module.settings.context.name_prefix}-CHEF01_PublicIP"
  location            = module.settings.context.location
  resource_group_name = module.settings.context.resource_group_name
  allocation_method   = "Static"
}

resource "azurerm_availability_set" "avset_chef" {
  name                         = "${module.settings.context.name_prefix}-CHEF"
  location                     = module.settings.context.location
  resource_group_name          = module.settings.context.resource_group_name
  platform_fault_domain_count  = module.settings.context.availability_set.platform_fault_domain_count
  platform_update_domain_count = module.settings.context.availability_set.platform_update_domain_count
  managed                      = true
}

module "chef" {
  source = "git::https://dev.azure.com/Example/terraform/_git/terraform-azurerm-linux_virtual_machine?ref=2.11.0"

  instances = {
    CHEF01 = {
      hostname                      = "${module.settings.context.name_prefix}-CHEF01"
      hostnum                       = null
      public_ip_id                  = azurerm_public_ip.CHEF01_public_ip.id
      private_ip_address_allocation = "Dynamic"
      enable_accelerated_networking = true
    }
  }

  settings = module.settings.context
  administrator = {
    password = var.ADMIN_PASSWORD
    username = var.ADMIN_USERNAME
  }

  disk_storage_account_type = "Premium_LRS"
  subnet                    = module.network.subnets.TOOLS
  image_from_market         = module.settings.linux_rhel8_image

  hosting = {
    availability_set_id = azurerm_availability_set.avset_chef.id
    size                = "Standard_DS3_v2"
  }
}