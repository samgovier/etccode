variable "env_settings" {
  description = "The common environment settings."
  type = object({
    location            = string
    resource_group_name = string
  })
}

variable "name" {
  description = "The name of the function application."
  type        = string
}

variable "service_plan_id" {
  description = "The service plan to put the application under."
  type        = string
}

variable "storage_account_name" {
  description = "The name of the storage account to link for storing data."
  type        = string
}

variable "storage_account_access_key" {
  description = "The access key for the storage account for storing data."
  type        = string
  sensitive   = true
}

variable "app_insights_key" {
  description = "The instrumentation key for linking to Application Insights."
  type        = string
}

variable "app_settings" {
  description = "Map of key value pairs that act at the application settings."
  type        = map(string)
}

variable "functions_extension_version" {
  description = "The Function App's runtime version."
  default     = "~4"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the application."
  type        = map(any)
  default     = {}
}
