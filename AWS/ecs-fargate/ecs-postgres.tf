################################################################################
# Postgres (container-based, disabled when var.rds_db = true)
################################################################################

resource "aws_ecs_task_definition" "dbeaver_db" {
  count = var.rds_db ? 0 : 1

  family                   = "DBeaverTeamEdition-${var.deployment_id}-db"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  volume {
    name = "${var.deployment_id}-cloudbeaver_db_data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.cloudbeaver_db_data.id
      root_directory = "/"
    }
  }

  container_definitions = jsonencode([{
    name        = "${var.deployment_id}-postgres"
    image       = "${var.image_source}/cloudbeaver-postgres:16"
    essential   = true
    environment = var.cloudbeaver-db-env
    mountPoints = [{
      containerPath = "/var/lib/postgresql/data"
      sourceVolume  = "${var.deployment_id}-cloudbeaver_db_data"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "DBeaverTeamEdition-${var.deployment_id}"
        awslogs-region        = var.aws_region
        awslogs-create-group  = "true"
        awslogs-stream-prefix = "db"
      }
    }
    portMappings = [{
      name          = "${var.deployment_id}-postgres"
      protocol      = "tcp"
      containerPort = 5432
      hostPort      = 5432
    }]
  }])
}

resource "aws_ecs_service" "postgres" {
  count = var.rds_db ? 0 : 1

  name            = "${var.deployment_id}-postgres"
  cluster         = module.ecs_cluster.id
  task_definition = aws_ecs_task_definition.dbeaver_db[0].arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    security_groups  = [aws_security_group.dbeaver_te_private.id]
    subnets          = local.private_subnets
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "${var.deployment_id}-postgres"
      client_alias {
        dns_name = "${var.deployment_id}-postgres"
        port     = 5432
      }
    }
  }

  tags = {
    Env  = var.deployment_id
    Name = "DBeaverTeamEdition-postgres"
  }
}
