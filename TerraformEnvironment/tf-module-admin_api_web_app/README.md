# Introduction 
`tf-admin_api_web_app` is a Terraform module with the specific design of creating all the components of an Admin API Web App, Service Plan, slots, and various other settings. `variables` contains all the objects that are set by the caller. `outputs` contains all the data that can be received and used by the caller.

Resources used in this module:
* [azurerm_windows_web_app_slot](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_web_app_slot)
* [azurerm_monitor_autoscale_setting](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_autoscale_setting)
* [azurerm_app_configuration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_configuration)
* [azurerm_app_service_certificate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_certificate)
* [azurerm_app_service_custom_hostname_binding](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_custom_hostname_binding)
* [azurerm_app_service_certificate_binding](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_certificate_binding)

Data sources:
* [azurerm_app_configuration_keys](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/app_configuration_keys)

# Getting Started
This module can be implemented by using the `module` block in terraform calling code. To point to this module, use the `source` attribute and point to the git SSH clone link from Azure DevOps.

# Build and Test
This module can be tested manually by running `terraform plan`/`validate`/`apply` and providing the variables directly at the CLI.