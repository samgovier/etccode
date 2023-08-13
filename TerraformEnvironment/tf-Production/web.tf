# overall service plan
module "tf-service-plan" {
  source = "git"

  name         = "${local.env_settings.env}api-${local.env_settings.postfix}"
  env_settings = local.env_settings
  sku_name     = "P3v2"
  tags         = local.common_tags
}

## https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_autoscale_setting
resource "azurerm_monitor_autoscale_setting" "tf-service-plan-autoscale" {
  name                = "Scale Out By CPU Usage"
  resource_group_name = local.env_settings.resource_group_name
  location            = local.env_settings.location
  target_resource_id  = module.tf-service-plan.id
  tags                = local.common_tags
  profile {
    name = "CPU Scale Condition"
    capacity {
      minimum = 2
      maximum = 9
      default = 2
    }
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = module.tf-service-plan.id
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
        metric_resource_id = module.tf-service-plan.id
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

# web app
module "tf-web-app-insights" {
  source = "git"

  name             = "${local.env_settings.env}api-${local.env_settings.postfix}"
  env_settings     = local.env_settings
  application_type = "web"
  tags             = local.common_tags
}

module "tf-web-app" {
  source = "git"

  name            = "${local.env_settings.env}api-${local.env_settings.postfix}"
  env_settings    = local.env_settings
  service_plan_id = module.tf-service-plan.id
  tags            = local.common_tags

  app_settings             = { for kvp in data.azurerm_app_configuration_keys.tf-web-appsetting-keys.items : kvp.key => kvp.value }
  azsql_connection_strings = { for kvp in data.azurerm_app_configuration_keys.tf-web-azsqlconnstring-keys.items : kvp.key => kvp.value }
}

resource "azurerm_app_service_custom_hostname_binding" "tf-custom-hostname" {
  hostname            = "onlineservices.example.com"
  app_service_name    = "${local.env_settings.env}api-${local.env_settings.postfix}"
  resource_group_name = local.env_settings.resource_group_name
}

resource "azurerm_app_service_certificate_binding" "tf-cert-binding" {
  certificate_id      = azurerm_app_service_certificate.tf--wildcard.id
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.tf-custom-hostname.id
  ssl_state           = "SniEnabled"
}

resource "azurerm_windows_web_app_slot" "tf-web-app-slot" {
  name           = "PreDeploymentSlot"
  app_service_id = module.tf-web-app.id

  site_config {}

  app_settings = { for kvp in data.azurerm_app_configuration_keys.tf-web-slot-appsetting-keys.items : kvp.key => kvp.value }

  dynamic "connection_string" {
    for_each = { for kvp in data.azurerm_app_configuration_keys.tf-web-slot-azsqlconnstring-keys.items : kvp.key => kvp.value }
    iterator = constr
    content {
      name  = constr.key
      type  = "SQLAzure"
      value = constr.value
    }
  }

  tags = local.common_tags
}

# function app
module "tf-function-app-insights" {
  source = "git"

  name             = "${local.env_settings.env}af-${local.env_settings.postfix}"
  env_settings     = local.env_settings
  application_type = "other"
  tags             = local.common_tags
}

module "tf-function-app" {
  source = "git"

  name                       = "${local.env_settings.env}af-${local.env_settings.postfix}"
  env_settings               = local.env_settings
  storage_account_name       = module.tf-ascprod-storage-account.storage_account.name
  storage_account_access_key = module.tf-ascprod-storage-account.storage_account.primary_access_key
  app_insights_key           = module.tf-function-app-insights.instrumentation_key
  service_plan_id            = module.tf-service-plan.id
  tags                       = local.common_tags

  functions_extension_version = "~1"

  app_settings = { for kvp in data.azurerm_app_configuration_keys.tf-function-config-keys.items : kvp.key => kvp.value }
}
