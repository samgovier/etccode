resource "azurerm_static_site" "tf-static_site" {

  # basic settings
  name                = var.name
  resource_group_name = var.env_settings.resource_group_name
  location            = var.env_settings.location
  tags                = var.tags

  # variable settings
  sku_tier = var.sku.tier
  sku_size = var.sku.size

}
