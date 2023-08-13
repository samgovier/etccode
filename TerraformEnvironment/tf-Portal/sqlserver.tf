data "azurerm_key_vault_secret" "asc-nimbus" {
  name         = "asc-${local.env_settings.env}-nimbus"
  key_vault_id = data.azurerm_key_vault.terraform-kv.id
}

resource "azurerm_mssql_server" "asc-mssql-nimbus" {
  name                = "asc-${local.env_settings.env}-nimbus"
  resource_group_name = local.env_settings.resource_group_name
  location            = local.locations.primary_location

  version                      = "12.0"
  administrator_login          = ""
  administrator_login_password = data.azurerm_key_vault_secret.asc-nimbus.value

  tags = local.common_tags

  azuread_administrator {
    login_username = "DevOps"
    object_id      = ""
    tenant_id      = ""
  }
}

resource "azurerm_mssql_firewall_rule" "asc-mssql-nimbus-fw-rules" {
  for_each         = local.azurerm_mssql_firewall_rules
  name             = each.key
  server_id        = azurerm_mssql_server.asc-mssql-nimbus.id
  start_ip_address = each.value["start_ip_address"]
  end_ip_address   = each.value["end_ip_address"]
}

locals {
  azurerm_mssql_firewall_rules = {
    "Allow VPN Connections" = {
      start_ip_address = "1.2.3.4",
      end_ip_address   = "1.2.3.4"
    },
    "EU VPN Connections" = {
      start_ip_address = "1.2.3.4",
      end_ip_address   = "1.2.3.4"
    },
    "South Africa Office" = {
      start_ip_address = "1.2.3.4",
      end_ip_address   = "1.2.3.4"
    },
    "UK Office" = {
      start_ip_address = "1.2.3.4",
      end_ip_address   = "1.2.3.4"
    }
  }
}
