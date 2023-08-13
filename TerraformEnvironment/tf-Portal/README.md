# Introduction 
`tf-Portal` is a Terraform repository for the Portal environments. This is a root module; all build here is to be applied directly to Azure.

Resources used in this repository:
* [azurerm_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group)
* [azurerm_static_site](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/static_site)
* [azurerm_static_site_custom_domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/static_site_custom_domain)
* [azurerm_cdn_frontdoor_profile](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_profile)
* [azurerm_cdn_frontdoor_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_endpoint)
* [azurerm_cdn_frontdoor_origin_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin_group)
* [azurerm_cdn_frontdoor_origin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin)
* [azurerm_cdn_frontdoor_route](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_route)
* [azurerm_cdn_frontdoor_custom_domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain)
* [azurerm_cdn_frontdoor_custom_domain_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain_association)
* [azurerm_cdn_frontdoor_security_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_security_policy)
* [azurerm_cdn_frontdoor_firewall_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_firewall_policy)
* [azurerm_mssql_server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server)
* [azurerm_mssql_firewall_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_firewall_rule)

Data sources:
* [azurerm_key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault)
* [azurerm_key_vault_secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret)

## Staging Workspace
This repository utilizes Terraform workspaces: production is deployed via the `default` workspace, and staging is deployed via the `staging` workspace. You can read more about workspaces and how to use them here: https://developer.hashicorp.com/terraform/language/state/workspaces

To use the staging workspace:

1. Run `terraform init` to allow Azure connection and interaction.
1. Run `terraform workspace select staging` to switch to the Staging workspace.
1. Make changes and run commands in Staging as desired.

# Deploying Config Changes to App Services
For the applications under this repository, config is stored in Azure App Configuration objects. If App Config changes need to be made, they need to folow the workflow of changing the App Config objects, and then deploying the changes via Terraform to the services.

To deploy changes to app settings:
1. Deploy the change to the SLOT first
    1. Browse to the corresponding Azure App Config in Azure Portal that contains `*-SLOT`
    2. Add the change that you need to make and save
    3. Run `terraform apply` on the `tf-Portal` directory: this should show that it is applying your new setting to the slot. Finish the apply.
2. Wait for the release and the slot swap for the new setting to be ready in production.
3. Deploy the change to the remaining slot
    1. Browse to the corresponding Azure App Config in Azure Portal that contains `*-PRIMARY`
    2. Add the change that you need to make and save
    3. Run `terraform apply` on the `tf-Portal` directory: this should show that the setting is being applied to the slot again, which is EXPECTED. The current config change should be matching in the Primary slot. Finish the apply.

# Getting Started
Infrastructure changes are made with the `terraform` CLI: any changes to the objects in this repository should be made with Terraform.

1. Make code changes as needed in Production.
1. Run `terraform init` to allow Azure connection and interaction.
1. Run `terraform fmt` and `terraform validate` to make sure the code is functional.
1. Commit to the `main` branch.
1. Run `terraform plan` to confirm changes that will be made to Production.
1. Run `terraform apply` to make those changes.

## Azure App Configuration Access Control
In order to operate Terraform setup in this repository, the user needs to have `App Configuration Data Owner` rights on all app configuration objects. See the wiki