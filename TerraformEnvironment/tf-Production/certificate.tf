resource "azurerm_app_service_certificate" "tf-wildcard" {
  name                = "webspace"
  resource_group_name = local.env_settings.resource_group_name
  location            = local.env_settings.location
  key_vault_secret_id = data.azurerm_key_vault_secret.tf-wildcard-secret.id
}

data "azurerm_key_vault" "tf-keyvault2" {
  name                = "KeyVault2"
  resource_group_name = "Support"
}

data "azurerm_key_vault_secret" "tf-wildcard-secret" {
  name         = "wildcard"
  key_vault_id = data.azurerm_key_vault.tf-keyvault2.id
}
