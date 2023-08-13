resource "azurerm_resource_group" "portal-rg" {
  name     = local.env_settings.resource_group_name
  location = local.locations.primary_location
  tags     = local.common_tags
}