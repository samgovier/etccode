resource "azurerm_windows_web_app" "tf-windows_web_app" {

  # basic settings
  name                = var.name
  resource_group_name = var.env_settings.resource_group_name
  location            = var.env_settings.location

  # variable settings
  service_plan_id = var.service_plan_id
  tags            = var.tags
  app_settings    = var.app_settings

  # dynamic block to create SQLAzure connection strings
  dynamic "connection_string" {
    for_each = var.azsql_connection_strings
    iterator = constr
    content {
      name  = constr.key
      type  = "SQLAzure"
      value = constr.value
    }
  }

  # constant settings
  https_only = true
  site_config {}
}