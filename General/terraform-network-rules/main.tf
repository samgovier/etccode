resource "azurerm_network_security_rule" "Allow-HTTPS-to-Chef" {
  for_each                     = toset(lookup(local.rules_subnet_map, "Allow-HTTPS-to-Chef", []))
  name                         = "Allow-HTTPS-to-Chef"
  protocol                     = "TCP"
  source_port_range            = "*"
  destination_port_range       = "443"
  source_address_prefixes      = ["", "", ""]
  destination_address_prefixes = ["", ""]
  access                       = "Allow"
  priority                     = 123
  direction                    = "Inbound"
  resource_group_name          = var.context.resource_group_name
  network_security_group_name  = "${var.context.name_prefix}-NSG_${each.value}"
}

resource "azurerm_network_security_rule" "Allow-ChefAutomate-inbound" {
  for_each                     = toset(lookup(local.rules_subnet_map, "Allow-ChefAutomate-inbound", []))
  name                         = "Allow-ChefAutomate-inbound"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = 443
  source_address_prefix        = ""
  destination_address_prefixes = local.address_prefixes.TOOLS
  access                       = "Allow"
  priority                     = 1100
  direction                    = "Inbound"
  resource_group_name          = var.context.resource_group_name
  network_security_group_name  = "${var.context.name_prefix}-NSG_${each.value}"
}

resource "azurerm_network_security_rule" "Allow-ChefAutomate-outbound" {
  for_each                    = toset(lookup(local.rules_subnet_map, "Allow-ChefAutomate-outbound", []))
  name                        = "Allow-ChefAutomate-outbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 443
  source_address_prefix       = "${var.context.ip_prefix}.0.0/16"
  destination_address_prefix  = ""
  access                      = "Allow"
  priority                    = 1104
  direction                   = "Outbound"
  resource_group_name         = var.context.resource_group_name
  network_security_group_name = "${var.context.name_prefix}-NSG_${each.value}"
}

resource "azurerm_network_security_rule" "Allow-chef" {
  for_each                     = toset(lookup(local.rules_subnet_map, "Allow-chef", []))
  name                         = "Allow-chef"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = 443
  source_address_prefix        = "${var.context.ip_prefix}.0.0/16"
  destination_address_prefixes = ["", ""]
  access                       = "Allow"
  priority                     = 1101
  direction                    = "Outbound"
  resource_group_name          = var.context.resource_group_name
  network_security_group_name  = "${var.context.name_prefix}-NSG_${each.value}"
}

resource "azurerm_network_security_rule" "Allow-RDP-SSH-From-MA" {
  for_each                    = toset(lookup(local.rules_subnet_map, "Allow-RDP-SSH-From-MA", []))
  name                        = "Allow-RDP-SSH-From-MA"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_ranges     = ["3389", "22"]
  source_address_prefixes     = [""]
  destination_address_prefix  = "${var.context.ip_prefix}.0.0/16"
  access                      = "Allow"
  priority                    = 202
  direction                   = "Inbound"
  resource_group_name         = var.context.resource_group_name
  network_security_group_name = "${var.context.name_prefix}-NSG_${each.value}"
}