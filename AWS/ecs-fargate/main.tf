provider "aws" {
  region = var.dbeaver-aws-region
}

resource "aws_ecs_cluster" "dbeaver_te" {
  name = "DBeaverTeamEdition"
}

################################################################################
# Namespace
################################################################################

resource "aws_service_discovery_private_dns_namespace" "dbeaver" {
  name        = var.dbeaver_te_default_ns
  description = "DBeaver SD Namespace"
  vpc         = aws_vpc.dbeaver_net.id
}


################################################################################
# EFS
################################################################################

resource "aws_efs_file_system" "cloudbeaver_db_data" {
  creation_token = "cloudbeaver_db_data"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = "false"
  tags = {
    Name = "DBeaver TE DATA EFS"
  }
}

resource "aws_efs_mount_target" "cloudbeaver_db_data_mt" {
  count = length(aws_subnet.private_subnets)
  file_system_id = aws_efs_file_system.cloudbeaver_db_data.id
  subnet_id      = aws_subnet.private_subnets[count.index].id
  security_groups = [aws_security_group.dbeaver_efs.id]
}

resource "aws_efs_file_system" "cloudbeaver_rm_data" {
  creation_token = "cloudbeaver_rm_data"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = "false"
  tags = {
    Name = "DBeaver TE RM DATA EFS"
  }
}

resource "aws_efs_mount_target" "cloudbeaver_rm_data_mt" {
  count = length(aws_subnet.private_subnets)
  file_system_id = aws_efs_file_system.cloudbeaver_rm_data.id
  subnet_id      = aws_subnet.private_subnets[count.index].id
  security_groups = [aws_security_group.dbeaver_efs.id]
}


resource "aws_efs_file_system" "cloudbeaver_dc_data" {
  creation_token = "cloudbeaver_dc_data"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = "false"
  tags = {
    Name = "DBeaver TE DC DATA EFS"
  }
}

resource "aws_efs_mount_target" "cloudbeaver_dc_data_mt" {
  count = length(aws_subnet.private_subnets)
  file_system_id = aws_efs_file_system.cloudbeaver_dc_data.id
  subnet_id      = aws_subnet.private_subnets[count.index].id
  security_groups = [aws_security_group.dbeaver_efs.id]
}


################################################################################
# Postgres
################################################################################

resource "aws_ecs_task_definition" "dbeaver_db" {

  family                   = "DBeaverTeamEdition-db"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  volume {
    name      = "cloudbeaver_db_data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.cloudbeaver_db_data.id
      root_directory = "/"
    }
  }
  container_definitions = jsonencode([{
    name        = "postgres"
    image       = "${var.aws_account_id}.dkr.ecr.${var.dbeaver-aws-region}.amazonaws.com/cloudbeaver-db:${var.image_version}"
    essential   = true
    environment = var.cloudbeaver-db-env
    mountPoints = [{
              "containerPath": "/var/lib/postgresql/data",
              "sourceVolume": "cloudbeaver_db_data"
    }]
    logConfiguration = {
                "logDriver": "awslogs"
                "options": {
                    "awslogs-group": "DBeaverTeamEdition",
                    "awslogs-region": "${var.dbeaver-aws-region}",
                    "awslogs-create-group": "true",
                    "awslogs-stream-prefix": "db"
                }
    }
    portMappings = [{
      name = "postgres"
      protocol      = "tcp"
      containerPort = 5432
      hostPort      = 5432
    }]
  }])
}

resource "aws_ecs_service" "postgres" {

  depends_on = [
    aws_ecs_task_definition.dbeaver_db,
    aws_security_group.dbeaver_te_private
  ]

  name            = "postgres"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_db.arn
  launch_type     = "FARGATE"
  desired_count   = 1 # Setting the number of containers we want deployed to 3

  network_configuration {
    security_groups = [aws_security_group.dbeaver_te_private.id]
    subnets          = aws_subnet.private_subnets[*].id
    assign_public_ip = false # Providing our containers with public IPs
  }
  service_connect_configuration {
    enabled = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "postgres"
      client_alias {
        dns_name = "postgres"
        port = 5432
      }

    }
  }
}

################################################################################
# Kafka
################################################################################

resource "aws_ecs_task_definition" "kafka" {
  family                   = "DBeaverTeamEdition-kafka"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = jsonencode([{
    name        = "kafka"
    image       = "dbeaver/cloudbeaver-kafka:3.2"
    essential   = true
    environment = var.cloudbeaver-kafka-env
    logConfiguration = {
                "logDriver": "awslogs"
                "options": {
                    "awslogs-group": "DBeaverTeamEdition",
                    "awslogs-region": "${var.dbeaver-aws-region}",
                    "awslogs-create-group": "true",
                    "awslogs-stream-prefix": "kafka"
                }
    }
    portMappings = [{
      name = "kafka"
      protocol      = "tcp"
      containerPort = 9092
      hostPort      = 9092
    }]
  }])
}

resource "aws_ecs_service" "kafka" {

  depends_on = [
    aws_ecs_task_definition.kafka,
    aws_security_group.dbeaver_te_private
  ]

  name            = "kafka"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.kafka.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    security_groups = [aws_security_group.dbeaver_te_private.id]
    subnets          = aws_subnet.private_subnets[*].id
    assign_public_ip = false
  }
  service_connect_configuration {
    enabled = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "kafka"
      client_alias {
        dns_name = "kafka"
        port = 9092
      }

    }
  }
}



################################################################################
# DBeaver TE DC
################################################################################

resource "aws_ecs_task_definition" "dbeaver_dc" {
  family                   = "DBeaverTeamEdition-dc"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 4096
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  volume {
    name      = "cloudbeaver_dc_data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.cloudbeaver_dc_data.id
      root_directory = "/"
    }
  }
  container_definitions = jsonencode([{
    name        = "cloudbeaver-dc"
    image       = "${var.aws_account_id}.dkr.ecr.${var.dbeaver-aws-region}.amazonaws.com/cloudbeaver-dc:${var.image_version}"
    essential   = true
    environment = var.cloudbeaver-dc-env
    mountPoints = [{
              "containerPath": "/opt/domain-controller/workspace",
              "sourceVolume": "cloudbeaver_dc_data"
    }]
    logConfiguration = {
                "logDriver": "awslogs"
                "options": {
                    "awslogs-group": "DBeaverTeamEdition",
                    "awslogs-region": "${var.dbeaver-aws-region}",
                    "awslogs-create-group": "true",
                    "awslogs-stream-prefix": "dc"
                }
    }
    portMappings = [{
      name = "cloudbeaver-dc"
      protocol      = "tcp"
      containerPort = 8970
      hostPort      = 8970
    }]
  }])
}

resource "aws_ecs_service" "dc" {

  depends_on = [
    aws_ecs_task_definition.dbeaver_dc,
    aws_security_group.dbeaver_te
  ]

  name            = "cloudbeaver-dc"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_dc.arn
  launch_type     = "FARGATE"
  desired_count   = 1 # Setting the number of containers we want deployed to 3

  network_configuration {
    security_groups = [aws_security_group.dbeaver_te.id]
    subnets          = aws_subnet.private_subnets[*].id
    assign_public_ip = false # Providing our containers with public IPs
  }
  service_connect_configuration {
    enabled = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "cloudbeaver-dc"
      client_alias {
        dns_name = "cloudbeaver-dc"
        port = 8970
      }
    }
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.dbeaver_dc.arn
    container_name   = "cloudbeaver-dc"
    container_port   = 8970
  }
}

################################################################################
# DBeaver TE RM
################################################################################

resource "aws_ecs_task_definition" "dbeaver_rm" {
  family                   = "DBeaverTeamEdition-rm"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  volume {
    name      = "cloudbeaver_rm_data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.cloudbeaver_rm_data.id
      root_directory = "/"
    }
  }
  container_definitions = jsonencode([{
    name        = "cloudbeaver-rm"
    image       = "${var.aws_account_id}.dkr.ecr.${var.dbeaver-aws-region}.amazonaws.com/cloudbeaver-rm:${var.image_version}"
    essential   = true
    environment = var.cloudbeaver-shared-env
    mountPoints = [{
              "containerPath": "/opt/resource-manager/workspace",
              "sourceVolume": "cloudbeaver_rm_data"
    }]
    logConfiguration = {
                "logDriver": "awslogs"
                "options": {
                    "awslogs-group": "DBeaverTeamEdition",
                    "awslogs-region": "${var.dbeaver-aws-region}",
                    "awslogs-create-group": "true",
                    "awslogs-stream-prefix": "rm"
                }
    }
    portMappings = [{
      name = "cloudbeaver-rm"
      protocol      = "tcp"
      containerPort = 8971
      hostPort      = 8971
    }]
  }])
}

resource "aws_ecs_service" "rm" {

  depends_on = [
    aws_ecs_task_definition.dbeaver_rm,
    aws_security_group.dbeaver_te
  ]

  name            = "cloudbeaver-rm"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_rm.arn
  launch_type     = "FARGATE"
  desired_count   = 1 # Setting the number of containers we want deployed to 3

  network_configuration {
    security_groups = [aws_security_group.dbeaver_te.id]
    subnets          = aws_subnet.private_subnets[*].id
    assign_public_ip = false # Providing our containers with public IPs
  }
  service_connect_configuration {
    enabled = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "cloudbeaver-rm"
      client_alias {
        dns_name = "cloudbeaver-rm"
        port = 8971
      }
    }
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.dbeaver_rm.arn
    container_name   = "cloudbeaver-rm"
    container_port   = 8971
  }
}

################################################################################
# DBeaver TE QM
################################################################################

resource "aws_ecs_task_definition" "dbeaver_qm" {
  family                   = "DBeaverTeamEdition-qm"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = jsonencode([{
    name        = "cloudbeaver-qm"
    image       = "${var.aws_account_id}.dkr.ecr.${var.dbeaver-aws-region}.amazonaws.com/cloudbeaver-qm:${var.image_version}"
    essential   = true
    environment = var.cloudbeaver-shared-env
    logConfiguration = {
                "logDriver": "awslogs"
                "options": {
                    "awslogs-group": "DBeaverTeamEdition",
                    "awslogs-region": "${var.dbeaver-aws-region}",
                    "awslogs-create-group": "true",
                    "awslogs-stream-prefix": "qm"
                }
    }
    portMappings = [{
      name = "cloudbeaver-qm"
      protocol      = "tcp"
      containerPort = 8972
      hostPort      = 8972
    }]
  }])
}

resource "aws_ecs_service" "qm" {

  depends_on = [
    aws_ecs_task_definition.dbeaver_qm,
    aws_security_group.dbeaver_te
  ]

  name            = "cloudbeaver-qm"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_qm.arn
  launch_type     = "FARGATE"
  desired_count   = 1 # Setting the number of containers we want deployed to 3

  network_configuration {
    security_groups = [aws_security_group.dbeaver_te.id]
    subnets          = aws_subnet.private_subnets[*].id
    assign_public_ip = false # Providing our containers with public IPs
  }
  service_connect_configuration {
    enabled = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "cloudbeaver-qm"
      client_alias {
        dns_name = "cloudbeaver-qm"
        port = 8972
      }
    }
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.dbeaver_qm.arn
    container_name   = "cloudbeaver-qm"
    container_port   = 8972
  }
}

################################################################################
# DBeaver TE TM
################################################################################

resource "aws_ecs_task_definition" "dbeaver_tm" {
  family                   = "DBeaverTeamEdition-tm"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  container_definitions = jsonencode([{
    name        = "cloudbeaver-tm"
    image       = "${var.aws_account_id}.dkr.ecr.${var.dbeaver-aws-region}.amazonaws.com/cloudbeaver-tm:${var.image_version}"
    essential   = true
    environment = var.cloudbeaver-shared-env
    logConfiguration = {
                "logDriver": "awslogs"
                "options": {
                    "awslogs-group": "DBeaverTeamEdition",
                    "awslogs-region": "${var.dbeaver-aws-region}",
                    "awslogs-create-group": "true",
                    "awslogs-stream-prefix": "tm"
                }
    }
    portMappings = [{
      name = "cloudbeaver-tm"
      protocol      = "tcp"
      containerPort = 8973
      hostPort      = 8973
    }]
  }])
}

resource "aws_ecs_service" "tm" {

  depends_on = [
    aws_ecs_task_definition.dbeaver_tm,
    aws_security_group.dbeaver_te
  ]

  name            = "cloudbeaver-tm"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_tm.arn
  launch_type     = "FARGATE"
  desired_count   = 1 # Setting the number of containers we want deployed to 3

  network_configuration {
    security_groups = [aws_security_group.dbeaver_te.id]
    subnets          = aws_subnet.private_subnets[*].id
    assign_public_ip = false # Providing our containers with public IPs
  }
  service_connect_configuration {
    enabled = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "cloudbeaver-tm"
      client_alias {
        dns_name = "cloudbeaver-tm"
        port = 8973
      }
    }
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.dbeaver_tm.arn
    container_name   = "cloudbeaver-tm"
    container_port   = 8973
  }
}


################################################################################
# DBeaver TE CloudBeaver
################################################################################

resource "aws_ecs_task_definition" "dbeaver_te" {
  family                   = "DBeaverTeamEdition-te"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = jsonencode([{
    name        = "cloudbeaver-te"
    image       = "${var.aws_account_id}.dkr.ecr.${var.dbeaver-aws-region}.amazonaws.com/cloudbeaver-te:${var.image_version}"
    essential   = true
    environment = var.cloudbeaver-shared-env
    logConfiguration = {
                "logDriver": "awslogs"
                "options": {
                    "awslogs-group": "DBeaverTeamEdition",
                    "awslogs-region": "${var.dbeaver-aws-region}",
                    "awslogs-create-group": "true",
                    "awslogs-stream-prefix": "te"
                }
    }
    portMappings = [{
      name = "cloudbeaver-te"
      protocol      = "tcp"
      containerPort = 8978
      hostPort      = 8978
    }]
  }])
}

resource "aws_ecs_service" "te" {

  depends_on = [
    aws_ecs_task_definition.dbeaver_te,
    aws_security_group.dbeaver_te,
    aws_lb_target_group.dbeaver_te
  ]

  name            = "cloudbeaver-te"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_te.arn
  launch_type     = "FARGATE"
  desired_count   = 1 # Setting the number of containers we want deployed to 3

  network_configuration {
    security_groups = [aws_security_group.dbeaver_te.id]
    subnets          = aws_subnet.private_subnets[*].id
    assign_public_ip = false # Providing our containers with public IPs
  }
  service_connect_configuration {
    enabled = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "cloudbeaver-te"
      client_alias {
        dns_name = "cloudbeaver-te"
        port = 8978
      }
    }
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.dbeaver_te.arn
    container_name   = "cloudbeaver-te"
    container_port   = 8978
  }
}
