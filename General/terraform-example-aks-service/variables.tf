variable "tower_settings" {
  type = object({
    location            = string
    resource_group_name = string
    tower_letter        = string
    name_prefix         = string
  })
}

variable "aks_default_systempool" {
  description = "Default Settings for AKS System Nodepool"
  type = object({
    name                         = optional(string)
    node_count                   = optional(number)
    enable_auto_scaling          = optional(bool)
    min_count                    = optional(number)
    max_count                    = optional(number)
    vm_size                      = optional(string)
    only_critical_addons_enabled = optional(bool)
    orchestrator_version         = string
  })
}

variable "aks_default_userpool" {
  description = "Define the 'user' node pool settings of the AKS cluster"
  type = object({
    name                 = optional(string)
    node_count           = optional(number)
    enable_auto_scaling  = optional(bool)
    min_count            = optional(number)
    max_count            = optional(number)
    vm_size              = optional(string)
    orchestrator_version = string
  })
}

variable "aks_additional_userpools" {
  description = "Define the 'user' node pool settings of the AKS cluster"
  type = map(object({
    name                 = string
    node_count           = number
    enable_auto_scaling  = bool
    min_count            = number
    max_count            = number
    vm_size              = string
    orchestrator_version = string
  }))
  default = {}
}

variable "vnet_id" {
  description = "VNET id"
}

variable "vnet_subnet_id" {
  description = "vnet_subnet_id"
}

variable "registry_name" {
  description = "registry name"
}

variable "registry_resource_group" {
  description = "resource group of the registry"
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster "
  default     = "AKS-SERVICE"
}

variable "aks_cluster_control_plane_version" {
  description = "Version of the Control Plane of the AKS Cluster"
}

variable "as_addresses_prefix" {
  type        = list(string)
  description = "as (subnet) addresses prefix"
  default     = []
}

variable "aks_address_prefix" {
  description = "aks (subnet) address prefix"
}

variable "context_name_prefix" {
  description = "context name prefix"
}

variable "dns_resource_group_name" {
  description = "the resource group where the dns server is"
}