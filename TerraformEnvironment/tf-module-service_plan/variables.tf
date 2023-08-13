variable "env_settings" {
  description = "The common environment settings."
  type = object({
    location            = string
    resource_group_name = string
  })
}

variable "name" {
  description = "The name of the service plan."
  type        = string
}

variable "sku_name" {
  description = "The name of the service plan SKU."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the service plan."
  type        = map(any)
  default     = {}
}