output "file_system_id" {
  description = "The ID of the EFS file system"
  value       = aws_efs_file_system.this.id
  depends_on  = [aws_efs_mount_target.this]
}

output "file_system_arn" {
  description = "The ARN of the EFS file system"
  value       = aws_efs_file_system.this.arn
  depends_on  = [aws_efs_mount_target.this]
}

output "access_point_id" {
  description = "The ID of the EFS access point"
  value       = try(aws_efs_access_point.this[0].id, null)
  depends_on  = [aws_efs_mount_target.this]
}

output "access_point_arn" {
  description = "The ARN of the EFS access point"
  value       = try(aws_efs_access_point.this[0].arn, null)
  depends_on  = [aws_efs_mount_target.this]
}

output "mount_target_ids" {
  description = "List of mount target IDs"
  value       = aws_efs_mount_target.this[*].id
}
