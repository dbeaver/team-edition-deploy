################################################################################
# Kafka
################################################################################

resource "aws_ecs_task_definition" "kafka" {
  family                   = "DBeaverTeamEdition-${var.deployment_id}-kafka"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = jsonencode([{
    name      = "${var.deployment_id}-kafka"
    image     = "${var.image_source}/cloudbeaver-kafka:3.9"
    essential = true
    environment = concat(var.cloudbeaver-kafka-env, [
      {
        name  = "KAFKA_CFG_CONTROLLER_QUORUM_VOTERS"
        value = "0@localhost:9093"
      },
      {
        name  = "KAFKA_CFG_ADVERTISED_LISTENERS"
        value = "PLAINTEXT://${var.deployment_id}-kafka:9092"
      }
    ])
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "DBeaverTeamEdition-${var.deployment_id}"
        awslogs-region        = var.aws_region
        awslogs-create-group  = "true"
        awslogs-stream-prefix = "kafka"
      }
    }
    portMappings = [{
      name          = "${var.deployment_id}-kafka"
      protocol      = "tcp"
      containerPort = 9092
      hostPort      = 9092
    }]
  }])
}

resource "aws_ecs_service" "kafka" {
  name            = "${var.deployment_id}-kafka"
  cluster         = module.ecs_cluster.id
  task_definition = aws_ecs_task_definition.kafka.arn
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
      port_name = "${var.deployment_id}-kafka"
      client_alias {
        dns_name = "${var.deployment_id}-kafka"
        port     = 9092
      }
    }
  }

  tags = {
    Env  = var.deployment_id
    Name = "DBeaverTeamEdition-kafka"
  }
}
