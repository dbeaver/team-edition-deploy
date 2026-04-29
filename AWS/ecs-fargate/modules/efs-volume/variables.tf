variable "name" {
  description = "Name suffix for the EFS file system"
  type        = string
}

variable "deployment_id" {
  description = "Deployment identifier used for naming and tagging"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names and tags"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for EFS mount targets"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs to attach to mount targets"
  type        = list(string)
}

variable "encrypted" {
  description = "Whether to enable encryption at rest"
  type        = bool
  default     = false
}

variable "performance_mode" {
  description = "EFS performance mode"
  type        = string
  default     = "generalPurpose"
}

variable "throughput_mode" {
  description = "EFS throughput mode"
  type        = string
  default     = "bursting"
}

variable "access_point" {
  description = "Optional access point configuration"
  type = object({
    path        = string
    owner_uid   = number
    owner_gid   = number
    permissions = string
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
