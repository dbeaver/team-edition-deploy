data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${var.name_prefix}-${var.deployment_id}-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_ecs" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "efs_access" {
  name        = "${var.name_prefix}-${var.deployment_id}-EFSAccessPolicy"
  description = "EFS access policy scoped to ${var.deployment_id} file systems"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets",
          "elasticfilesystem:DescribeMountTargetSecurityGroups",
          "elasticfilesystem:DescribeTags",
          "elasticfilesystem:CreateMountTarget",
          "elasticfilesystem:DeleteMountTarget",
          "elasticfilesystem:ModifyMountTargetSecurityGroups",
          "elasticfilesystem:ListTagsForResource",
          "elasticfilesystem:TagResource",
          "elasticfilesystem:UntagResource"
        ]
        Resource = var.efs_arns
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:CreateTags",
          "elasticfilesystem:DeleteTags",
          "elasticfilesystem:DescribeFileSystemPolicy",
          "elasticfilesystem:PutFileSystemPolicy"
        ]
        Resource = var.efs_arns
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = concat(var.efs_arns, var.efs_ap_arns)
      },
      {
        Effect   = "Allow"
        Action   = "elasticfilesystem:DescribeAccessPoints"
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_efs" {
  role       = aws_iam_role.execution.name
  policy_arn = aws_iam_policy.efs_access.arn
}

resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "${var.name_prefix}-${var.deployment_id}-CloudWatchLogsPolicy"
  description = "Scoped CloudWatch Logs policy for ${var.deployment_id}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "arn:aws:logs:*:*:log-group:${var.name_prefix_full}-${var.deployment_id}*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_logs" {
  role       = aws_iam_role.execution.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}


resource "aws_iam_role" "task" {
  name               = "${var.name_prefix}-${var.deployment_id}-ecsTaskRoleExec"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "task_ssm" {
  role       = aws_iam_role.task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "task_logs" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}
