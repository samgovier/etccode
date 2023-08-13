resource "azurerm_service_plan" "tf-service_plan" {

  # basic settings
  name                = var.name
  resource_group_name = var.env_settings.resource_group_name
  location            = var.env_settings.location

  # variable settings
  sku_name = var.sku_name
  tags     = var.tags

  # constant settings
  os_type = "Windows"
}