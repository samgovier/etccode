variable "env_settings" {
  description = "The common environment settings."
  type = object({
    location            = string
    resource_group_name = string
  })
}

variable "name" {
  description = "The name of the static site."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the application."
  type        = map(any)
  default     = {}
}

variable "sku" {
  description = "The sku of the static site."
  type = object({
    tier = string
    size = string
  })
  default = {
    tier = "standard"
    size = "standard"
  }
}
