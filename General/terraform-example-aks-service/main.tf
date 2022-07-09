terraform {
  required_version = "~> 1.0"
  experiments      = [module_variable_optional_attrs]
}

locals {
  name              = "${var.context_name_prefix}-${var.aks_cluster_name}"
  private_link_name = lower("${local.name}.privatelink.${var.tower_settings.location}.azmk8s.io")

  aks_default_systempool = defaults(var.aks_default_systempool, {
    name                         = "systemnp"
    node_count                   = 2
    enable_auto_scaling          = true
    min_count                    = 2
    max_count                    = 10
    vm_size                      = "Standard_DS4_v2"
    only_critical_addons_enabled = true
  })

  aks_default_userpool = defaults(var.aks_default_userpool, {
    name                = "usernp01"
    node_count          = 2
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 10
    vm_size             = "Standard_DS2_v2"
  })

}

data "azuread_client_config" "clientconfig" {}

data "azurerm_resource_group" "rg" {
  name = var.tower_settings.resource_group_name
}

data "azurerm_container_registry" "acr" {
  name                = var.registry_name
  resource_group_name = var.registry_resource_group
}

data "azuread_group" "cluster_user_groups" {
  for_each = toset(var.cluster_user_group_ids)

  display_name     = each.value
  security_enabled = true
}

data "azurerm_virtual_network" "prod-vnet" {
  count               = var.tower_settings.resource_group_name == "QA" ? 0 : 1
  name                = "Prod"
  resource_group_name = "Prod"
}

data "azurerm_private_dns_zone" "privatedns" {
  name                = local.private_dns_name
  resource_group_name = var.dns_resource_group_name
  depends_on = [
    azurerm_private_dns_zone.example,
  ]
}