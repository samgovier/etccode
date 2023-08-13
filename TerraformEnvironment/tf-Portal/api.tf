data "azurerm_key_vault" "portal-cert-kv" {
  name                = terraform.workspace == "default" ? "KeyVault" : "staging"
  resource_group_name = terraform.workspace == "default" ? "Support" : "Staging"
}

data "azurerm_key_vault_secret" "portal-cert-kv-secret" {
  name         = terraform.workspace == "default" ?  "wildcard" : "staging"
  key_vault_id = data.azurerm_key_vault.portal-cert-kv.id
}

module "portal-app-service-regions-default" {
  for_each = terraform.workspace == "default" ? local.locations.default : {}

  source = "git"

  env_settings = {
    location            = each.value
    resource_group_name = local.env_settings.resource_group_name
    env                 = local.env_settings.env
  }

  cloudflare_custom_hostname = {
    hostname                 = "portal.${local.root_domain}"
    cert_webspace_name       = "${local.env_settings.resource_group_name}-${each.value}webspace"
    cert_key_vault_secret_id = data.azurerm_key_vault_secret.portal-cert-kv-secret.id
  }

  name = "admin-${local.env_settings.env}-${each.key}"
  tags = local.common_tags
}

module "portal-app-service-regions-staging" {
  for_each = terraform.workspace == "staging" ? local.locations.staging : {}

  source = "git"

  env_settings = {
    location            = each.value
    resource_group_name = local.env_settings.resource_group_name
    env                 = local.env_settings.env
  }

  cloudflare_custom_hostname = {
    hostname                 = "admin.${local.root_domain}"
    cert_webspace_name       = "${local.env_settings.resource_group_name}-${each.value}webspace"
    cert_key_vault_secret_id = data.azurerm_key_vault_secret.portal-cert-kv-secret.id
  }

  name = "portal-${local.env_settings.env}-${each.key}"
  tags = local.common_tags
}