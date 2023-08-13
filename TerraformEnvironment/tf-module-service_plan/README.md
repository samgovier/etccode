# Introduction 
`tf-service_plan` is a Terraform module for implementing an App Service Plan that matches the standard. `variables` contains all the objects that are set by the caller. `outputs` contains all the data that can be received and used by the caller.

Resources used in this module:
* [azurerm_service_plan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan)

# Getting Started
This module can be implemented by using the `module` block in terraform calling code. To point to this module, use the `source` attribute and point to the git SSH clone link from Azure DevOps.

# Build and Test
This module can be tested manually by running `terraform plan`/`validate`/`apply` and providing the variables directly at the CLI.