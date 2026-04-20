variable "name" {
  description = "Service name"
  type        = string
}

variable "deployment_id" {
  description = "Deployment identifier"
  type        = string
}

variable "name_prefix" {
  description = "Short prefix for resource names"
  type        = string
}

variable "name_prefix_full" {
  description = "Full prefix for resource names"
  type        = string
}

variable "family_suffix" {
  description = "Task definition family suffix"
  type        = string
  default     = null
}

variable "log_prefix" {
  description = "CloudWatch Logs stream prefix"
  type        = string
  default     = null
}

variable "image" {
  description = "Container image URI"
  type        = string
}

variable "cpu" {
  description = "CPU units for the task"
  type        = number
}

variable "memory" {
  description = "Memory in MiB for the task"
  type        = number
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "container_name_override" {
  description = "Override container name"
  type        = string
  default     = null
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "efs_volumes" {
  description = "EFS volumes to attach to the task"
  type = list(object({
    name               = string
    file_system_id     = string
    root_directory     = optional(string, null)
    transit_encryption = optional(bool, false)
    access_point_id    = optional(string, null)
    mount_path         = string
  }))
  default = []
}

variable "cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs for the ECS service"
  type        = list(string)
}

variable "subnet_ids" {
  description = "Subnet IDs for the ECS service"
  type        = list(string)
}

variable "service_connect_namespace_arn" {
  description = "ARN of the Service Connect namespace"
  type        = string
}

variable "desired_count" {
  description = "Number of task instances"
  type        = number
  default     = 1
}

variable "enable_execute_command" {
  description = "Enable ECS Exec"
  type        = bool
  default     = true
}

variable "assign_public_ip" {
  description = "Assign a public IP to the task ENI"
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
