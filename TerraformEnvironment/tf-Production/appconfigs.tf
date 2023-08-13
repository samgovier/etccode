# Functions Config
resource "azurerm_app_configuration" "tf-function-config" {
  name                = "${local.env_settings.env}af-${local.env_settings.postfix}-config-PRIMARY"
  resource_group_name = local.env_settings.resource_group_name
  location            = local.env_settings.location
  sku                 = "standard"
  tags                = local.common_tags
}

data "azurerm_app_configuration_keys" "tf-function-config-keys" {
  configuration_store_id = azurerm_app_configuration.tf-function-config.id
}


# Primary Config
resource "azurerm_app_configuration" "tf-web-config" {
  name                = "${local.env_settings.env}api-${local.env_settings.postfix}-config-PRIMARY"
  resource_group_name = local.env_settings.resource_group_name
  location            = local.env_settings.location
  sku                 = "standard"
  tags                = local.common_tags
}

data "azurerm_app_configuration_keys" "tf-web-appsetting-keys" {
  configuration_store_id = azurerm_app_configuration.tf-web-config.id
  label                  = "appsetting"
}

data "azurerm_app_configuration_keys" "tf-web-azsqlconnstring-keys" {
  configuration_store_id = azurerm_app_configuration.tf-web-config.id
  label                  = "azsqlconnstring"
}

# Slot Config
resource "azurerm_app_configuration" "tf-web-slot-config" {
  name                = "${local.env_settings.env}api-${local.env_settings.postfix}-config-SLOT"
  resource_group_name = local.env_settings.resource_group_name
  location            = local.env_settings.location
  sku                 = "standard"
  tags                = local.common_tags
}

data "azurerm_app_configuration_keys" "tf-web-slot-appsetting-keys" {
  configuration_store_id = azurerm_app_configuration.tf-web-slot-config.id
  label                  = "appsetting"
}

data "azurerm_app_configuration_keys" "tf-web-slot-azsqlconnstring-keys" {
  configuration_store_id = azurerm_app_configuration.tf-web-slot-config.id
  label                  = "azsqlconnstring"
}

# Reporting Primary Config
resource "azurerm_app_configuration" "tf-reporting-config" {
  name                = "Reporting${title(local.env_settings.env)}-${local.env_settings.postfix}-config-PRIMARY"
  resource_group_name = local.env_settings.resource_group_name
  location            = local.env_settings.location
  sku                 = "standard"
  tags                = local.common_tags
}

data "azurerm_app_configuration_keys" "tf-reporting-web-appsetting-keys" {
  configuration_store_id = azurerm_app_configuration.tf-reporting-config.id
  label                  = "appsetting"
}

data "azurerm_app_configuration_keys" "tf-reporting-web-azsqlconnstring-keys" {
  configuration_store_id = azurerm_app_configuration.tf-reporting-config.id
  label                  = "azsqlconnstring"
}

# Reporting Slot Config
resource "azurerm_app_configuration" "tf-reporting-slot-config" {
  name                = "Reporting${title(local.env_settings.env)}-${local.env_settings.postfix}-config-SLOT"
  resource_group_name = local.env_settings.resource_group_name
  location            = local.env_settings.location
  sku                 = "standard"
  tags                = local.common_tags
}

data "azurerm_app_configuration_keys" "tf-reporting-web-slot-appsetting-keys" {
  configuration_store_id = azurerm_app_configuration.tf-reporting-slot-config.id
  label                  = "appsetting"
}

data "azurerm_app_configuration_keys" "tf-reporting-web-slot-azsqlconnstring-keys" {
  configuration_store_id = azurerm_app_configuration.tf-reporting-slot-config.id
  label                  = "azsqlconnstring"
}
