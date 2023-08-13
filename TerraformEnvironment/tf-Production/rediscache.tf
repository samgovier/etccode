resource "azurerm_redis_cache" "tf-redis-cache" {
  name                = terraform.workspace == "default" ? "asprdred-${local.env_settings.postfix}" : "as${local.env_settings.env}red-${local.env_settings.postfix}"
  location            = local.env_settings.location
  resource_group_name = local.env_settings.resource_group_name
  capacity            = 0
  family              = "C"
  sku_name            = "Standard"
  tags                = local.common_tags
}