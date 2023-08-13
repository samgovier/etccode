module "portal-service-plan" {
  source = "git"

  name         = var.name
  env_settings = var.env_settings
  sku_name     = "P2v2"
  tags         = var.tags
}

module "portal-windows-web-app" {
  source = "git"

  name            = var.name
  env_settings    = var.env_settings
  service_plan_id = module.portal-service-plan.id
  app_settings    = { for kvp in data.azurerm_app_configuration_keys.portal-windows-web-app-config-keys.items : kvp.key => kvp.value }
  tags            = var.tags
}

resource "azurerm_app_configuration" "portal-windows-web-app-config" {
  name                = "${var.name}-config-PRIMARY"
  resource_group_name = var.env_settings.resource_group_name
  location            = var.env_settings.location
  sku                 = "standard"
  tags                = var.tags
}

data "azurerm_app_configuration_keys" "portal-windows-web-app-config-keys" {
  configuration_store_id = azurerm_app_configuration.portal-windows-web-app-config.id
}

module "portal-web-app-insights" {
  source = "git"

  name             = var.name
  env_settings     = var.env_settings
  application_type = "web"
  tags             = var.tags
}

resource "azurerm_app_configuration" "portal-windows-web-app-slot-config" {
  name                = "${var.name}-config-SLOT"
  resource_group_name = var.env_settings.resource_group_name
  location            = var.env_settings.location
  sku                 = "standard"
  tags                = var.tags
}

data "azurerm_app_configuration_keys" "portal-windows-web-app-slot-config-keys" {
  configuration_store_id = azurerm_app_configuration.portal-windows-web-app-slot-config.id
}

resource "azurerm_windows_web_app_slot" "portal-web-app-slot" {
  name           = "PreDeploymentSlot"
  app_service_id = module.portal-windows-web-app.id

  site_config {}
  app_settings = { for kvp in data.azurerm_app_configuration_keys.portal-windows-web-app-slot-config-keys.items : kvp.key => kvp.value }
  tags         = var.tags
}

resource "azurerm_windows_web_app_slot" "portal-web-app-dev-slot" {
  count          = var.env_settings.env != "prod" ? 1 : 0
  name           = "DevelopmentSlot"
  app_service_id = module.portal-windows-web-app.id

  site_config {}
  app_settings = { for kvp in data.azurerm_app_configuration_keys.portal-windows-web-app-slot-config-keys.items : kvp.key => kvp.value }
  tags         = var.tags
}

resource "azurerm_app_service_certificate" "portal-custom-hostname-cert" {
  name                = var.cloudflare_custom_hostname.cert_webspace_name
  resource_group_name = var.env_settings.resource_group_name
  location            = var.env_settings.location
  key_vault_secret_id = var.cloudflare_custom_hostname.cert_key_vault_secret_id
  tags                = var.tags

}

resource "azurerm_app_service_custom_hostname_binding" "portal-custom-hostname" {
  hostname         = var.cloudflare_custom_hostname.hostname
  app_service_name = var.name

  # set to "lower" for azure casing inconsistencies, this resource was created and imported in Azure UI
  resource_group_name = lower(var.env_settings.resource_group_name)
}

resource "azurerm_app_service_certificate_binding" "portal-custom-hostname-cert-binding" {
  certificate_id      = azurerm_app_service_certificate.portal-custom-hostname-cert.id
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.portal-custom-hostname.id
  ssl_state           = "SniEnabled"
}

## https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_autoscale_setting
resource "azurerm_monitor_autoscale_setting" "portal-service-plan-autoscale" {
  name                = "${var.name}-autoscale"
  resource_group_name = var.env_settings.resource_group_name
  location            = var.env_settings.location
  target_resource_id  = module.portal-service-plan.id
  tags                = var.tags
  profile {
    name = "CPU Scale Condition"
    capacity {
      minimum = 1
      maximum = 5
      default = 1
    }
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = module.portal-service-plan.id
        operator           = "GreaterThanOrEqual"
        statistic          = "Average"
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT5M"
        threshold          = 70
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT5M"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = module.portal-service-plan.id
        operator           = "LessThan"
        statistic          = "Average"
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT10M"
        threshold          = 40
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT5M"
      }
    }
  }
}
