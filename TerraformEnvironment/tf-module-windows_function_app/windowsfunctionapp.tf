resource "azurerm_windows_function_app" "tf-windows_function_app" {

  # basic settings
  name                = var.name
  resource_group_name = var.env_settings.resource_group_name
  location            = var.env_settings.location

  # variable settings
  service_plan_id             = var.service_plan_id
  tags                        = var.tags
  storage_account_name        = var.storage_account_name
  storage_account_access_key  = var.storage_account_access_key
  functions_extension_version = var.functions_extension_version
  app_settings                = var.app_settings

  # constant settings
  https_only = true

  # Site Configuration
  site_config {
    application_insights_key = var.app_insights_key
    http2_enabled            = true

    cors {
      allowed_origins = [
        "https://functions.azure.com",
        "https://functions-staging.azure.com",
        "https://functions-next.azure.com"
      ]
    }
  }
}