terraform {
  # versions are kept to minor upgrades only; major will need strategy
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
    key                  = "admin.tfstate"
    subscription_id      = "0eb45c33-d093-4fdb-9805-c29d80928123"
  }
}

data "azurerm_key_vault" "terraform-kv" {
  name                = "asc-devops-terraform-kv"
  resource_group_name = "DevOpsResources"
  provider            = azurerm.prodProvider
}

provider "azurerm" {
  features {}
  subscription_id = terraform.workspace == "default" ? "0eb45c33-d093-4fdb-9805-c29d80928123" : "fd9c7898-0633-4e10-b0b0-3ae9765ec46a"
}

provider "azurerm" {
  features {}
  alias           = "prodProvider"
  subscription_id = "0eb45c33-d093-4fdb-9805-c29d80928123"
}

locals {
  common_tags = {
    terraform       = true
    "Business Unit" = ""
    Environment     = "${terraform.workspace == "default" ? "Production" : "${title(terraform.workspace)}"}"
  }

  # the env-based key-value pairs in locations are as follows:
  #   key matches to the shortcode used in naming (ie. as a postfix),
  #   value matches the azure supported location string, used for placing objects
  locations = {
    primary_location = "eastus2",
    default = {
      "eastus2" = "EastUS2",
      "westeu"  = "WestEurope",
      "seau"    = "AustraliaSoutheast"
    },
    staging = {
      "eastus2" = "EastUS2",
      "westeu"  = "WestEurope"
    }
  }

  # root_domain is the base for custom domains: it's different for production and staging
  root_domain = terraform.workspace == "default" ? "prod.com" : "staging.com"

  env_settings = {
    resource_group_name = "${terraform.workspace == "default" ? "Portal-Production" : "Portal-${title(terraform.workspace)}"}"
    env                 = "${terraform.workspace == "default" ? "prod" : terraform.workspace}"
  }
}