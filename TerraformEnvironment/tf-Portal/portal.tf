resource "azurerm_static_site" "portal-static" {
  name                = "portal-${local.env_settings.env}-${local.locations.primary_location}"
  location            = local.locations.primary_location
  resource_group_name = local.env_settings.resource_group_name
  sku_tier            = "Standard"
  sku_size            = "Standard"
  tags                = local.common_tags
}

module "portal-static-app-insights" {
  source = "git"

  name = "portal-${local.env_settings.env}-${local.locations.primary_location}"
  env_settings = {
    location            = local.locations.primary_location
    resource_group_name = local.env_settings.resource_group_name
  }
  application_type = "other"
  tags             = local.common_tags
}

resource "azurerm_static_site_custom_domain" "portal-static-custom-domain" {
  domain_name     = "portal.${local.root_domain}"
  static_site_id  = azurerm_static_site.portal-static.id
  validation_type = "cname-delegation"
}
