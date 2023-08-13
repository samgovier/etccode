resource "azurerm_storage_account" "tf-storage_account" {

  # basic settings
  name                = var.name
  resource_group_name = var.env_settings.resource_group_name
  location            = var.env_settings.location

  # variable settings
  account_kind                    = var.account_settings.account_kind
  account_tier                    = var.account_settings.account_tier
  account_replication_type        = var.account_settings.account_replication_type
  enable_https_traffic_only       = var.enable_https_traffic_only
  public_network_access_enabled   = var.public_network_access_enabled
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  tags                            = var.tags

  # constant settings
}
