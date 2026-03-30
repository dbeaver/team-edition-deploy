################################################################################
# DBeaver TE RM
################################################################################

resource "aws_ecs_task_definition" "dbeaver_rm" {
  family                   = "DBeaverTeamEdition-${var.deployment_id}-rm"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecs_task_role_exec.arn

  volume {
    name = "${var.deployment_id}-cloudbeaver_rm_data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.cloudbeaver_rm_data.id
      root_directory = "/"
    }
  }

  volume {
    name = "${var.deployment_id}-cloudbeaver_certificates_public"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.cloudbeaver_certificates.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.certs_public.id
        iam             = "DISABLED"
      }
    }
  }

  container_definitions = jsonencode([{
    name        = "${var.deployment_id}-cloudbeaver-rm"
    image       = "${var.image_source}/cloudbeaver-rm:${var.dbeaver_te_version}"
    essential   = true
    environment = local.cloudbeaver_shared_env_modified
    mountPoints = [
      {
        containerPath = "/opt/resource-manager/workspace"
        sourceVolume  = "${var.deployment_id}-cloudbeaver_rm_data"
      },
      {
        containerPath = "/opt/resource-manager/conf/certificates"
        sourceVolume  = "${var.deployment_id}-cloudbeaver_certificates_public"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "DBeaverTeamEdition-${var.deployment_id}"
        awslogs-region        = var.aws_region
        awslogs-create-group  = "true"
        awslogs-stream-prefix = "rm"
      }
    }
    portMappings = [{
      name          = "${var.deployment_id}-cloudbeaver-rm"
      protocol      = "tcp"
      containerPort = 8971
      hostPort      = 8971
    }]
  }])
}

resource "aws_ecs_service" "rm" {
  name                   = "${var.deployment_id}-cloudbeaver-rm"
  cluster                = module.ecs_cluster.id
  task_definition        = aws_ecs_task_definition.dbeaver_rm.arn
  launch_type            = "FARGATE"
  desired_count          = var.desired_count["rm"]
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
      port_name = "${var.deployment_id}-cloudbeaver-rm"
      client_alias {
        dns_name = "${var.deployment_id}-cloudbeaver-rm"
        port     = 8971
      }
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dbeaver_rm.arn
    container_name   = "${var.deployment_id}-cloudbeaver-rm"
    container_port   = 8971
  }

  tags = {
    Env  = var.deployment_id
    Name = "DBeaverTeamEdition-rm"
  }
}
