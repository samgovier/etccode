resource "azurerm_resource_group" "prod" {
  name     = local.env_settings.resource_group_name
  location = local.env_settings.location
  tags     = local.common_tags
}