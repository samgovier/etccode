# Introduction 
`tf-Production` is a Terraform repository for the production environment for this web app. This is a root module; all build here is to be applied directly to Azure.

Resources used in this repository:
* [azurerm_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group)
* [azurerm_redis_cache](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redis_cache)
* [azurerm_app_service_custom_hostname_binding](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_custom_hostname_binding)
* [azurerm_windows_web_app_slot](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_web_app_slot)
* [azurerm_monitor_autoscale_setting](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_autoscale_setting)
* [azurerm_eventhub_namespace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace)
* [azurerm_eventhub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub)
* [azurerm_app_configuration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_configuration)
* [azurerm_app_service_certificate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_certificate)

Data sources:
* [azurerm_app_configuration_keys](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/app_configuration_keys)
* [azurerm_key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault)
* [azurerm_key_vault_secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret)

## Staging Workspace
For testing purposes, there are pieces of staging build throughout this module. However, the current build doesn't take staging into account and the Terraform workspace was deleted. Please do not re-create or use a non-default workspace without first reviewing and updating the code to accomodate that workspace and differentiate it from Production (ie. the `default` workspace).

# Deploying Config Changes to App Services
For the applications under this repository, config is stored in Azure App Configuration objects. If App Config changes need to be made, they need to folow the workflow of changing the App Config objects, and then deploying the changes via Terraform to the services.

To deploy changes to app settings and connection strings:
1. Deploy the change to the SLOT first
    1. Browse to the corresponding Azure App Config in Azure Portal that contains `*-SLOT`
    2. Add the change that you need to make and save:
        * If it's for a regular application setting, use the label `appsetting`
        * If it's for a `SQLAzure` connection string, use the label `azsqlconnstring`
        * `SQLAzure` is the only connection string type that I've seen thus far. If there's a new connection string with a different type, the windows web app needs to be redesigned to add the new connection string type. 
    3. Run `terraform apply` on the `tf-Production` directory: this should show that it is applying your new setting to the slot. Finish the apply.
2. Wait for the release and slot swap for the new setting to be ready in production.
3. Deploy the change to the remaining slot
    1. Browse to the corresponding Azure App Config in Azure Portal that contains `*-PRIMARY`
    2. Add the change that you need to make and save
    3. Run `terraform apply` on the `tf-Production` directory: this should show that the setting is being applied to the slot again, which is EXPECTED. The current config change should be matching in the Primary slot. Finish the apply.

__NOTE:__ There is an expected discrepancy between the configurations in Azure Functions and the corresponding Azure App Config. Some of the values displayed in the Function App config are backend settings uncontrolled by the regular config. These can be changed via different methodology: versioning, app insights, storage connection strings.

# Getting Started
Infrastructure changes are made with the `terraform` CLI: any changes to the objects in this repository should be made with Terraform. The below JSON file setup is required to work with this repository.

1. Make code changes as needed in Production.
1. Run `terraform init` to allow Azure connection and interaction.
1. Run `terraform fmt` and `terraform validate` to make sure the code is functional.
1. Commit to the `main` branch.
1. Run `terraform plan` to confirm changes that will be made to Production.
1. Run `terraform apply` to make those changes.

## Azure App Configuration Access Control
In order to operate Terraform setup in this repository, the user needs to have `App Configuration Data Owner` rights on all app configuration objects. See the wiki