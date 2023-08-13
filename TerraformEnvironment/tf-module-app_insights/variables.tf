variable "env_settings" {
  description = "The common environment settings."
  type = object({
    location            = string
    resource_group_name = string
  })
}

variable "tags" {
  description = "Tags to apply to the app insights component."
  type        = map(any)
  default     = {}
}

variable "name" {
  description = "The name of the app insights component."
  type        = string
}

variable "application_type" {
  description = "The type of App Insights to create."
  type        = string
}