variable "env_settings" {
  description = "The common environment settings."
  type = object({
    location            = string
    resource_group_name = string
    env                 = string
  })
}

variable "cloudflare_custom_hostname" {
  description = "Custom hostname settings to validate traffic routed through Cloudflare."
  type = object({
    hostname                 = string
    cert_webspace_name       = string
    cert_key_vault_secret_id = string
  })
}

variable "name" {
  description = "The shared name of the app service, plan, and insights object."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the admin api objects."
  type        = map(any)
  default     = {}
}
