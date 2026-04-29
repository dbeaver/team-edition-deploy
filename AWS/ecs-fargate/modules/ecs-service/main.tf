locals {
  family_suffix  = coalesce(var.family_suffix, var.name)
  log_prefix     = coalesce(var.log_prefix, local.family_suffix)
  container_name = coalesce(var.container_name_override, "${var.deployment_id}-${var.name}")
  service_name   = "${var.deployment_id}-${var.name}"
  family_name    = "${var.name_prefix_full}-${var.deployment_id}-${local.family_suffix}"
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.family_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  dynamic "volume" {
    for_each = var.efs_volumes
    content {
      name = "${var.deployment_id}-${volume.value.name}"
      efs_volume_configuration {
        file_system_id     = volume.value.file_system_id
        root_directory     = volume.value.access_point_id != null ? null : coalesce(volume.value.root_directory, "/")
        transit_encryption = volume.value.transit_encryption || volume.value.access_point_id != null ? "ENABLED" : null

        dynamic "authorization_config" {
          for_each = volume.value.access_point_id != null ? [1] : []
          content {
            access_point_id = volume.value.access_point_id
            iam             = "DISABLED"
          }
        }
      }
    }
  }

  container_definitions = jsonencode([{
    name      = local.container_name
    image     = var.image
    essential = true

    environment = var.environment

    mountPoints = [
      for vol in var.efs_volumes : {
        containerPath = vol.mount_path
        sourceVolume  = "${var.deployment_id}-${vol.name}"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = var.log_group_name
        awslogs-region        = var.aws_region
        awslogs-create-group  = "true"
        awslogs-stream-prefix = local.log_prefix
      }
    }

    portMappings = [{
      name          = local.service_name
      protocol      = "tcp"
      containerPort = var.container_port
      hostPort      = var.container_port
    }]
  }])

  tags = var.tags
}

resource "aws_ecs_service" "this" {
  name                   = local.service_name
  cluster                = var.cluster_id
  task_definition        = aws_ecs_task_definition.this.arn
  launch_type            = "FARGATE"
  desired_count          = var.desired_count
  enable_execute_command = var.enable_execute_command

  network_configuration {
    security_groups  = var.security_group_ids
    subnets          = var.subnet_ids
    assign_public_ip = var.assign_public_ip
  }

  service_connect_configuration {
    enabled   = true
    namespace = var.service_connect_namespace_arn
    service {
      port_name = local.service_name
      client_alias {
        dns_name = local.service_name
        port     = var.container_port
      }
    }
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = local.container_name
      container_port   = var.container_port
    }
  }

  tags = var.tags
}
