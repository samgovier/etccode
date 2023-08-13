module "tf-reporting-service-plan" {
  source = "git"

  name         = "Reporting${title(local.env_settings.env)}-${local.env_settings.postfix}"
  env_settings = local.env_settings
  sku_name     = "P1v2"
  tags         = local.common_tags
}

## https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_autoscale_setting
resource "azurerm_monitor_autoscale_setting" "tf-reporting-service-plan-autoscale" {
  name                = "Memory Percent Autoscale"
  resource_group_name = local.env_settings.resource_group_name
  location            = local.env_settings.location
  target_resource_id  = module.tf-reporting-service-plan.id
  tags                = local.common_tags
  profile {
    name = "Memory Scale Condition"
    capacity {
      minimum = 1
      maximum = 3
      default = 1
    }
    rule {
      metric_trigger {
        metric_name        = "MemoryPercentage"
        metric_resource_id = module.tf-reporting-service-plan.id
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
        metric_name        = "MemoryPercentage"
        metric_resource_id = module.tf-reporting-service-plan.id
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

module "tf-reporting-web-app-insights" {
  source = "git"

  name             = "Reporting${title(local.env_settings.env)}-${local.env_settings.postfix}"
  env_settings     = local.env_settings
  application_type = "web"
  tags             = local.common_tags
}

module "tf-reporting-web-app" {
  source = "git"

  name            = "Reporting${title(local.env_settings.env)}-${local.env_settings.postfix}"
  env_settings    = local.env_settings
  service_plan_id = module.tf-reporting-service-plan.id
  tags            = local.common_tags

  app_settings             = { for kvp in data.azurerm_app_configuration_keys.tf-reporting-web-appsetting-keys.items : kvp.key => kvp.value }
  azsql_connection_strings = { for kvp in data.azurerm_app_configuration_keys.tf-reporting-web-azsqlconnstring-keys.items : kvp.key => kvp.value }
}

resource "azurerm_app_service_custom_hostname_binding" "tf-reporting-custom-hostname" {
  hostname            = "reporting.example.com"
  app_service_name    = "Reporting${title(local.env_settings.env)}-${local.env_settings.postfix}"
  resource_group_name = local.env_settings.resource_group_name
}

resource "azurerm_app_service_certificate_binding" "tf-reporting-cert-binding" {
  certificate_id      = azurerm_app_service_certificate.tf-wildcard.id
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.tf-reporting-custom-hostname.id
  ssl_state           = "SniEnabled"
}

resource "azurerm_windows_web_app_slot" "tf-reporting-web-app-slot" {
  name           = "PreDeploymentSlot"
  app_service_id = module.tf-reporting-web-app.id

  site_config {}

  app_settings = { for kvp in data.azurerm_app_configuration_keys.tf-reporting-web-slot-appsetting-keys.items : kvp.key => kvp.value }

  dynamic "connection_string" {
    for_each = { for kvp in data.azurerm_app_configuration_keys.tf-reporting-web-slot-azsqlconnstring-keys.items : kvp.key => kvp.value }
    iterator = constr
    content {
      name  = constr.key
      type  = "SQLAzure"
      value = constr.value
    }
  }

  tags = local.common_tags
}
