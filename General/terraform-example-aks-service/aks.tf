# Manages a Managed Kubernetes Cluster (also known as AKS / Azure Kubernetes Service)
resource "azurerm_kubernetes_cluster" "AKS_cluster" {
  # Create System Node Pool for AKS-Service Cluster
  name                                = local.name
  kubernetes_version                  = var.aks_cluster_control_plane_version
  location                            = var.tower_settings.location
  resource_group_name                 = var.tower_settings.resource_group_name
  private_cluster_enabled             = true
  dns_prefix_private_cluster          = local.name
  private_cluster_public_fqdn_enabled = true

  identity {
    type                      = "UserAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.userassignedid.id
  }

  network_profile {
    network_plugin     = "kubenet"
    pod_cidr           = ""
    service_cidr       = ""
    docker_bridge_cidr = ""
    dns_service_ip     = ""
  }

  default_node_pool {
    name                         = local.aks_default_systempool.name
    vm_size                      = local.aks_default_systempool.vm_size
    vnet_subnet_id               = var.vnet_subnet_id
    enable_auto_scaling          = local.aks_default_systempool.enable_auto_scaling
    node_count                   = local.aks_default_systempool.node_count
    min_count                    = local.aks_default_systempool.min_count
    max_count                    = local.aks_default_systempool.max_count
    only_critical_addons_enabled = local.aks_default_systempool.only_critical_addons_enabled
    orchestrator_version         = local.aks_default_systempool.orchestrator_version
  }

  role_based_access_control {
    enabled = true

    azure_active_directory {
      managed = true
      admin_group_object_ids = [
        data.azuread_group.aks.id
      ]
    }
  }

  depends_on = [
    azurerm_role_assignment.subnet_contributor,
    azurerm_role_assignment.vnet_contributor,
    azurerm_private_dns_zone.privatelink_azmk8s,
    azurerm_private_dns_zone_virtual_network_link.linkexample,
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "AKS_cluster" {
  for_each = merge({ aks_default_userpool = local.aks_default_userpool }, var.aks_additional_userpools)

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.AKS_cluster.id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = var.vnet_subnet_id
  enable_auto_scaling   = each.value.enable_auto_scaling
  node_count            = each.value.node_count
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  orchestrator_version  = each.value.orchestrator_version
}