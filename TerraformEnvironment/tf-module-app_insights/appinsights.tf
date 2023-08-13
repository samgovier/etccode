resource "azurerm_application_insights" "tf-app_insights" {

  # basic settings
  name                = var.name
  resource_group_name = var.env_settings.resource_group_name
  location            = var.env_settings.location

  # variable settings
  application_type = var.application_type
  tags             = var.tags

  # constant settings
}