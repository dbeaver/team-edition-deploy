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

resource "aws_iam_policy" "CloudbeaverTeamEditionEFSAccessPolicy" {
  name        = "DBeaverTE-${var.deployment_id}-CloudbeaverTeamEditionEFSAccessPolicy"
  description = "Policy to allow access only to specific EFS resources for ${var.deployment_id} environment"
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
        Resource = [
          aws_efs_file_system.cloudbeaver_db_data.arn,
          aws_efs_file_system.cloudbeaver_rm_data.arn,
          aws_efs_file_system.cloudbeaver_tm_data.arn,
          aws_efs_file_system.cloudbeaver_dc_data.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:CreateTags",
          "elasticfilesystem:DeleteTags",
          "elasticfilesystem:DescribeFileSystemPolicy",
          "elasticfilesystem:PutFileSystemPolicy"
        ]
        Resource = [
          aws_efs_file_system.cloudbeaver_db_data.arn,
          aws_efs_file_system.cloudbeaver_rm_data.arn,
          aws_efs_file_system.cloudbeaver_tm_data.arn,
          aws_efs_file_system.cloudbeaver_dc_data.arn,
          aws_efs_file_system.cloudbeaver_certificates.arn
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ],
        "Resource" : [
          "${aws_efs_file_system.cloudbeaver_certificates.arn}",
          "${aws_efs_access_point.certs_public.arn}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : "elasticfilesystem:DescribeAccessPoints",
        "Resource" : "*"
      }
    ]
  })

  depends_on = [
    aws_efs_file_system.cloudbeaver_db_data,
    aws_efs_file_system.cloudbeaver_rm_data,
    aws_efs_file_system.cloudbeaver_tm_data,
    aws_efs_file_system.cloudbeaver_dc_data
  ]
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "DBeaverTE-${var.deployment_id}-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}



resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "TeamEditionEFSAccessPolicy_attachment" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = aws_iam_policy.CloudbeaverTeamEditionEFSAccessPolicy.arn
}
resource "aws_iam_role_policy_attachment" "logs_policy_attachment" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role" "ecs_task_role_exec" {
  name               = "DBeaverTE-${var.deployment_id}-ecsTaskRoleExec"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_exec_ssm" {
  role       = aws_iam_role.ecs_task_role_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_exec_logs" {
  role       = aws_iam_role.ecs_task_role_exec.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}