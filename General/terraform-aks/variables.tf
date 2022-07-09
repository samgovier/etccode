variable "SHARED_REGISTRY_SERVER" {}
variable "SHARED_REGISTRY_USERNAME" {}

variable "aks_nodepool_settings" {
  description = "Define the 'system' node pool settings of the AKS cluster"
  type = object({
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    node_count          = number
    vm_size             = string
  })
  default = {
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 10
    node_count          = 2
    vm_size             = "Standard_DS2_v2"
  }
}

variable "aks_additional_user_np02" {
  description = "Example of an additional AKS User nodepool"
  type = object({
    name                = string
    node_count          = number
    taints              = list(string)
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    vm_size             = string
  })
  default = {
    name                = "usernp02"
    node_count          = 2
    taints              = null
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 10
    vm_size             = "Standard_DS2_v2"
  }
}