output "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.execution.arn
  depends_on = [
    aws_iam_role_policy_attachment.execution_ecs,
    aws_iam_role_policy_attachment.execution_efs,
    aws_iam_role_policy_attachment.execution_logs,
  ]
}

output "execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = aws_iam_role.execution.name
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.task.arn
  depends_on = [
    aws_iam_role_policy_attachment.task_ssm,
    aws_iam_role_policy_attachment.task_logs,
  ]
}

output "task_role_name" {
  description = "Name of the ECS task role"
  value       = aws_iam_role.task.name
}
