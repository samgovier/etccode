provider "azurerm" {
  features {}
  skip_provider_registration = true
}

terraform {
  required_version = ">= 0.15"
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
    key                  = "prodfc-s-aks-service.tfstate"
  }
}

module "settings" {
  source = "../settings"
}

module "network" {
  source = "../data/network"
}

module "aks-service" {
  source = "git::https://example@dev.azure.com/example/terraform/_git/terraform-example-aks-service"
  tower_settings = {
    location            = module.settings.context.location
    resource_group_name = module.settings.context.resource_group_name
    tower_letter        = module.settings.context.tower_letter
    name_prefix         = module.settings.context.name_prefix
  }

  # To upgrade the cluster, change this value and the below "orchestrator_version" values
  aks_cluster_control_plane_version = "1.21.9"
  aks_default_systempool = {
    orchestrator_version = "1.21.9"
  }
  aks_default_userpool = {
    orchestrator_version = "1.21.9"
  }

  vnet_id                 = module.network.vnet.id
  vnet_subnet_id          = module.network.subnets.AKS-SERVICE.id
  registry_name           = split(".", var.SHARED_REGISTRY_SERVER)[0]
  registry_resource_group = "Shared"
  as_addresses_prefix     = []
  aks_address_prefix      = module.network.subnets.AKS-SERVICE.address_prefix
  context_name_prefix     = module.settings.context.name_prefix
  dns_resource_group_name = module.settings.context.resource_group_name
}