resource "azurerm_cdn_frontdoor_profile" "portal-fd-profile" {
  name                = "portal-${local.env_settings.env}-frontdoor"
  resource_group_name = local.env_settings.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = local.common_tags
}

resource "azurerm_cdn_frontdoor_endpoint" "portal-fd-endpoint" {
  name                     = "portal-${local.env_settings.env}-frontdoor-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.portal-fd-profile.id
  tags                     = local.common_tags
}

resource "azurerm_cdn_frontdoor_origin_group" "portal-fd-origin-group" {
  name                     = "portal-${local.env_settings.env}-backend"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.portal-fd-profile.id
  load_balancing {}
  health_probe {
    protocol            = "Https"
    interval_in_seconds = 60
  }
}

resource "azurerm_cdn_frontdoor_origin" "portal-fd-origin-default" {
  for_each                       = terraform.workspace == "default" ? local.locations.default : {}
  name                           = "portal-${local.env_settings.env}-${each.key}"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.portal-fd-origin-group.id
  host_name                      = "portal-${local.env_settings.env}-${each.key}.azurewebsites.net"
  origin_host_header             = "portal-${local.env_settings.env}-${each.key}.azurewebsites.net"
  certificate_name_check_enabled = true
  enabled                        = true # enabled is explicit due to a property conflict in 3.x. This can be removed in 4.x. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin
}

resource "azurerm_cdn_frontdoor_origin" "portal-fd-origin-staging" {
  for_each                       = terraform.workspace == "staging" ? local.locations.staging : {}
  name                           = "portal-${local.env_settings.env}-${each.key}"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.portal-fd-origin-group.id
  host_name                      = "portal-${local.env_settings.env}-${each.key}.azurewebsites.net"
  origin_host_header             = "portal-${local.env_settings.env}-${each.key}.azurewebsites.net"
  certificate_name_check_enabled = true
  enabled                        = true # enabled is explicit due to a property conflict in 3.x. This can be removed in 4.x. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin
}

resource "azurerm_cdn_frontdoor_route" "portal-fd-route" {
  enabled                         = terraform.workspace == "default" ? true : false
  name                            = "default-route"
  cdn_frontdoor_endpoint_id       = azurerm_cdn_frontdoor_endpoint.portal-fd-endpoint.id
  cdn_frontdoor_origin_group_id   = azurerm_cdn_frontdoor_origin_group.portal-fd-origin-group.id
  cdn_frontdoor_origin_ids        = concat(values(azurerm_cdn_frontdoor_origin.portal-fd-origin-staging)[*].id, values(azurerm_cdn_frontdoor_origin.portal-fd-origin-default)[*].id)
  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.portal-fd-custom-domain.id]
  forwarding_protocol             = "HttpsOnly"
  patterns_to_match               = ["/*"]
  supported_protocols             = ["Http", "Https"]
  https_redirect_enabled          = true
}

resource "azurerm_cdn_frontdoor_custom_domain" "portal-fd-custom-domain" {
  name                     = "portal-${local.env_settings.env}-frontdoor-custom-domain"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.portal-fd-profile.id
  host_name                = "portal.${local.root_domain}"
  tls {}
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "portal-fd-custom-domain-assoc" {
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.portal-fd-custom-domain.id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.portal-fd-route.id]
}

resource "azurerm_cdn_frontdoor_security_policy" "portal-fd-sec-policy" {
  name                     = "portal${local.env_settings.env}WAF-securitypolicy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.portal-fd-profile.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.portal-fd-waf.id
      association {
        patterns_to_match = ["/*"]
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.portal-fd-endpoint.id
        }
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.portal-fd-custom-domain.id
        }
      }
    }
  }
}

resource "azurerm_cdn_frontdoor_firewall_policy" "portal-fd-waf" {
  name                = "portal${local.env_settings.env}WAF"
  resource_group_name = local.env_settings.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
  mode                = "Detection"
  tags                = local.common_tags
}
