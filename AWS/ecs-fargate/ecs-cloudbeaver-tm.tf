################################################################################
# DBeaver TE TM
################################################################################

resource "aws_ecs_task_definition" "dbeaver_tm" {
  family                   = "DBeaverTeamEdition-${var.deployment_id}-tm"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecs_task_role_exec.arn

  volume {
    name = "${var.deployment_id}-cloudbeaver_tm_data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.cloudbeaver_tm_data.id
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
    name        = "${var.deployment_id}-cloudbeaver-tm"
    image       = "${var.image_source}/cloudbeaver-tm:${var.dbeaver_te_version}"
    essential   = true
    environment = local.cloudbeaver_shared_env_modified
    mountPoints = [
      {
        containerPath = "/opt/task-manager/workspace"
        sourceVolume  = "${var.deployment_id}-cloudbeaver_tm_data"
      },
      {
        containerPath = "/opt/task-manager/conf/certificates"
        sourceVolume  = "${var.deployment_id}-cloudbeaver_certificates_public"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "DBeaverTeamEdition-${var.deployment_id}"
        awslogs-region        = var.aws_region
        awslogs-create-group  = "true"
        awslogs-stream-prefix = "tm"
      }
    }
    portMappings = [{
      name          = "${var.deployment_id}-cloudbeaver-tm"
      protocol      = "tcp"
      containerPort = 8973
      hostPort      = 8973
    }]
  }])
}

resource "aws_ecs_service" "tm" {
  name                   = "${var.deployment_id}-cloudbeaver-tm"
  cluster                = module.ecs_cluster.id
  task_definition        = aws_ecs_task_definition.dbeaver_tm.arn
  launch_type            = "FARGATE"
  desired_count          = var.desired_count["tm"]
  enable_execute_command = true

  network_configuration {
    security_groups  = [aws_security_group.dbeaver_te.id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "${var.deployment_id}-cloudbeaver-tm"
      client_alias {
        dns_name = "${var.deployment_id}-cloudbeaver-tm"
        port     = 8973
      }
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dbeaver_tm.arn
    container_name   = "${var.deployment_id}-cloudbeaver-tm"
    container_port   = 8973
  }

  tags = {
    Env  = var.deployment_id
    Name = "DBeaverTeamEdition-tm"
  }
}
