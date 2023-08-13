resource "azurerm_eventhub_namespace" "tf-event-hub-namespace" {
  name                     = terraform.workspace == "default" ? "eventhub-prd-${local.env_settings.postfix}" : "eventhub-${local.env_settings.env}-${local.env_settings.postfix}"
  location                 = local.env_settings.location
  resource_group_name      = local.env_settings.resource_group_name
  sku                      = "Standard"
  capacity                 = 15
  auto_inflate_enabled     = true
  maximum_throughput_units = 20
  minimum_tls_version      = "1.0"

  tags = local.common_tags
}

resource "azurerm_eventhub" "tf-event-hub-inventory" {
  name                = ""
  namespace_name      = azurerm_eventhub_namespace.tf-event-hub-namespace.name
  resource_group_name = local.env_settings.resource_group_name
  partition_count     = 1
  message_retention   = 3
}

resource "azurerm_eventhub" "tf-event-hub" {
  name                = ""
  namespace_name      = azurerm_eventhub_namespace.tf-event-hub-namespace.name
  resource_group_name = local.env_settings.resource_group_name
  partition_count     = 1
  message_retention   = 1
}

resource "azurerm_eventhub_consumer_group" "tf-eventhub-cg-inventory-dataintegration" {
  name                = ""
  namespace_name      = azurerm_eventhub_namespace.tf-event-hub-namespace.name
  eventhub_name       = azurerm_eventhub.tf-event-hub-inventory.name
  resource_group_name = local.env_settings.resource_group_name
}

resource "azurerm_eventhub_consumer_group" "tf-eventhub-cg-afconsumer" {
  name                = ""
  namespace_name      = azurerm_eventhub_namespace.tf-event-hub-namespace.name
  eventhub_name       = azurerm_eventhub.tf-event-hub.name
  resource_group_name = local.env_settings.resource_group_name
}

resource "azurerm_eventhub_consumer_group" "tf-eventhub-cg-preview_data_consumer_group" {
  name                = ""
  namespace_name      = azurerm_eventhub_namespace.tf-event-hub-namespace.name
  eventhub_name       = azurerm_eventhub.tf-event-hub.name
  resource_group_name = local.env_settings.resource_group_name
}