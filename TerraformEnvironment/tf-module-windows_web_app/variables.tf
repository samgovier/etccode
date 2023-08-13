variable "env_settings" {
  description = "The common environment settings."
  type = object({
    location            = string
    resource_group_name = string
  })
}

variable "name" {
  description = "The name of the web application."
  type        = string
}

variable "service_plan_id" {
  description = "The service plan to put the application under."
  type        = string
}

variable "app_settings" {
  description = "Map of key value pairs that act at the application settings."
  type        = map(string)
}

variable "azsql_connection_strings" {
  description = "Connection Strings of type SQLAzure for application use."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to the application."
  type        = map(any)
  default     = {}
}
