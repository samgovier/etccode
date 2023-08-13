module "tf-ascprod-storage-account" {
  source = "git"

  name         = "asc${local.env_settings.env}${local.env_settings.postfix}"
  env_settings = local.env_settings
  account_settings = {
    account_kind             = "StorageV2"
    account_tier             = "Standard"
    account_replication_type = "LRS"
  }
  allow_nested_items_to_be_public = false
  tags                            = local.common_tags
}