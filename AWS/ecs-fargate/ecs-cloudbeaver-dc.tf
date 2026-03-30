################################################################################
# DBeaver TE DC
################################################################################

resource "aws_ecs_task_definition" "dbeaver_dc" {
  family                   = "DBeaverTeamEdition-${var.deployment_id}-dc"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecs_task_role_exec.arn

  volume {
    name = "${var.deployment_id}-cloudbeaver_dc_data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.cloudbeaver_dc_data.id
      root_directory = "/"
    }
  }

  volume {
    name = "${var.deployment_id}-cloudbeaver_certificates"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.cloudbeaver_certificates.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
    }
  }

  volume {
    name = "${var.deployment_id}-api_tokens"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.api_tokens.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
    }
  }

  container_definitions = jsonencode([{
    name        = "${var.deployment_id}-cloudbeaver-dc"
    image       = "${var.image_source}/cloudbeaver-dc:${var.dbeaver_te_version}"
    essential   = true
    environment = local.updated_cloudbeaver_dc_env
    mountPoints = [
      {
        containerPath = "/opt/domain-controller/workspace"
        sourceVolume  = "${var.deployment_id}-cloudbeaver_dc_data"
      },
      {
        containerPath = "/opt/domain-controller/conf/certificates"
        sourceVolume  = "${var.deployment_id}-cloudbeaver_certificates"
      },
      {
        containerPath = "/opt/domain-controller/conf/keys"
        sourceVolume  = "${var.deployment_id}-api_tokens"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "DBeaverTeamEdition-${var.deployment_id}"
        awslogs-region        = var.aws_region
        awslogs-create-group  = "true"
        awslogs-stream-prefix = "dc"
      }
    }
    portMappings = [{
      name          = "${var.deployment_id}-cloudbeaver-dc"
      protocol      = "tcp"
      containerPort = 8970
      hostPort      = 8970
    }]
  }])
}

resource "aws_ecs_service" "dc" {
  name                   = "${var.deployment_id}-cloudbeaver-dc"
  cluster                = module.ecs_cluster.id
  task_definition        = aws_ecs_task_definition.dbeaver_dc.arn
  launch_type            = "FARGATE"
  desired_count          = var.desired_count["dc"]
  enable_execute_command = true

  network_configuration {
    security_groups  = [aws_security_group.dbeaver_te.id]
    subnets          = local.private_subnets
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "${var.deployment_id}-cloudbeaver-dc"
      client_alias {
        dns_name = "${var.deployment_id}-cloudbeaver-dc"
        port     = 8970
      }
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dbeaver_dc.arn
    container_name   = "${var.deployment_id}-cloudbeaver-dc"
    container_port   = 8970
  }

  tags = {
    Env  = var.deployment_id
    Name = "DBeaverTeamEdition-dc"
  }
}
