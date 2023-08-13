variable "env_settings" {
  description = "The common environment settings."
  type = object({
    location            = string
    resource_group_name = string
  })
}

variable "name" {
  description = "The name of the storage account."
  type        = string
}

variable "account_settings" {
  description = "Overall settings for the storage account."
  type = object({
    account_kind             = string
    account_tier             = string
    account_replication_type = string
  })
}

variable "enable_https_traffic_only" {
  description = "Boolean which forces HTTPS if enabled."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Boolean determining public network access."
  type        = bool
  default     = true
}

variable "allow_nested_items_to_be_public" {
  description = "Boolean determining public Blob access."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the storage account."
  type        = map(any)
  default     = {}
}