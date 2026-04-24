variable "name" {
  description = "Name for the target group"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the target group"
  type        = string
}

variable "listener_arn" {
  description = "ARN of the ALB HTTPS listener"
  type        = string
}

variable "path_pattern" {
  description = "ALB path pattern for the listener rule"
  type        = string
}

variable "priority" {
  description = "Priority for the ALB listener rule"
  type        = number
  default     = 100
}

variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/"
}

variable "health_check_matcher" {
  description = "HTTP status codes for health check success"
  type        = string
  default     = "200,302"
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failures before marking unhealthy"
  type        = number
  default     = 7
}

variable "stickiness_enabled" {
  description = "Whether to enable session stickiness on the target group"
  type        = bool
  default     = false
}

variable "stickiness_duration" {
  description = "Cookie duration in seconds for session stickiness"
  type        = number
  default     = 86400
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
