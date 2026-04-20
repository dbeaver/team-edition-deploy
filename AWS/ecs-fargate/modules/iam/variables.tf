variable "deployment_id" {
  description = "Deployment identifier used for naming"
  type        = string
}

variable "name_prefix" {
  description = "Short prefix for resource names"
  type        = string
}

variable "name_prefix_full" {
  description = "Full prefix for log group ARN pattern"
  type        = string
}

variable "efs_arns" {
  description = "List of EFS file system ARNs for the access policy"
  type        = list(string)
  default     = []
}

variable "efs_ap_arns" {
  description = "List of EFS access point ARNs for the mount policy"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
