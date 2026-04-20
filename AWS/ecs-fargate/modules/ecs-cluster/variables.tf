variable "name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "capacity_providers" {
  description = "List of capacity providers associated with the cluster"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider" {
  description = "Name of the default capacity provider"
  type        = string
  default     = "FARGATE"
}

variable "default_capacity_provider_base" {
  description = "Minimum number of tasks to run with the default provider"
  type        = number
  default     = 1
}

variable "default_capacity_provider_weight" {
  description = "Relative percentage of tasks to run with the default provider"
  type        = number
  default     = 1
}

variable "container_insights_enabled" {
  description = "Whether to enable CloudWatch Container Insights"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
