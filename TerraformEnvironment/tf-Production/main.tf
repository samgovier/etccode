terraform {
  # versions are kept to minor upgrades only; major will need a strategy
  required_version = "~> 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  # state file is stored in a backend production storage account container
  backend "azurerm" {
    resource_group_name  = "DevOpsResources"
    storage_account_name = "devopsbitsarm"
    container_name       = "tf-prd"
    key                  = "production.tfstate"
    subscription_id      = ""
  }
}

provider "azurerm" {
  features {}
  subscription_id = ""
}

locals {
  common_tags = {
    terraform       = true
    "Environment"   = "${terraform.workspace == "default" ? "Production" : "${title(terraform.workspace)}"}"
  }

  # set to prod for default, otherwise use the workspace name
  env_settings = {
    resource_group_name = "${terraform.workspace == "default" ? "Production" : "${title(terraform.workspace)}"}"
    env                 = "${terraform.workspace == "default" ? "prod" : terraform.workspace}"
    location            = "eastus2"
    postfix             = ""
  }
}
