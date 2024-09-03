provider "aws" {
  region = var.aws_region
}

resource "aws_ecs_cluster" "dbeaver_te" {
  name = "${var.environment}-DBeaverTeamEdition"
  depends_on = [
    aws_ecr_repository.dbeaver_te,
    null_resource.build_push_dkr_img
  ]
}

locals {

  rds_db_url = length(aws_db_instance.rds_dbeaver_db) > 0 ? "jdbc:postgresql://${try(aws_db_instance.rds_dbeaver_db[0].address, "")}:5432/cloudbeaver" : ""

  cloudbeaver_dc_env_modified = [
    for item in var.cloudbeaver-dc-env : {
      name  = item.name
      value = (
        item.name == "CLOUDBEAVER_DC_BACKEND_DB_URL" && var.rds_db ? local.rds_db_url :
        item.name == "CLOUDBEAVER_QM_BACKEND_DB_URL" && var.rds_db ? local.rds_db_url :
        item.name == "CLOUDBEAVER_TM_BACKEND_DB_URL" && var.rds_db ? local.rds_db_url :
        item.value
      )
    }
  ]
  
  postgres_password = { for item in var.cloudbeaver-db-env : item.name => item.value }["POSTGRES_PASSWORD"]
  postgres_user     = { for item in var.cloudbeaver-db-env : item.name => item.value }["POSTGRES_USER"]

  updated_cloudbeaver_dc_env = [for item in local.cloudbeaver_dc_env_modified : {
    name  = item.name
    value = (
      item.name == "CLOUDBEAVER_DC_BACKEND_DB_PASSWORD" ? local.postgres_password :
      item.name == "CLOUDBEAVER_QM_BACKEND_DB_PASSWORD" ? local.postgres_password :
      item.name == "CLOUDBEAVER_TM_BACKEND_DB_PASSWORD" ? local.postgres_password :
      item.name == "CLOUDBEAVER_DC_BACKEND_DB_USER" ? local.postgres_user :
      item.name == "CLOUDBEAVER_QM_BACKEND_DB_USER" ? local.postgres_user :
      item.name == "CLOUDBEAVER_TM_BACKEND_DB_USER" ? local.postgres_user :
      item.value
    )
  }]
}


################################################################################
# Namespace
################################################################################

resource "aws_service_discovery_private_dns_namespace" "dbeaver" {
  name        = "${var.environment}-${var.dbeaver_te_default_ns}"
  description = "DBeaver SD Namespace"
  vpc         = aws_vpc.dbeaver_net.id
}


################################################################################
# EFS
################################################################################

resource "aws_efs_file_system" "cloudbeaver_db_data" {
  creation_token  = "${var.environment}-cloudbeaver_db_data"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags = {
    Env  = var.environment
    Name = "DBeaver TE DATA EFS"
  }
}

resource "aws_efs_mount_target" "cloudbeaver_db_data_mt" {
  count           = length(aws_subnet.private_subnets)
  file_system_id  = aws_efs_file_system.cloudbeaver_db_data.id
  subnet_id       = aws_subnet.private_subnets[count.index].id
  security_groups = [aws_security_group.dbeaver_efs.id]
}

resource "aws_efs_file_system" "cloudbeaver_rm_data" {
  creation_token  = "${var.environment}-cloudbeaver_rm_data"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags = {
    Env  = var.environment
    Name = "DBeaver TE RM DATA EFS"
  }
}

resource "aws_efs_mount_target" "cloudbeaver_rm_data_mt" {
  count           = length(aws_subnet.private_subnets)
  file_system_id  = aws_efs_file_system.cloudbeaver_rm_data.id
  subnet_id       = aws_subnet.private_subnets[count.index].id
  security_groups = [aws_security_group.dbeaver_efs.id]
}

resource "aws_efs_file_system" "cloudbeaver_tm_data" {
  creation_token  = "${var.environment}-cloudbeaver_tm_data"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags = {
    Env  = var.environment
    Name = "DBeaver TE TM DATA EFS"
  }
}

resource "aws_efs_mount_target" "cloudbeaver_tm_data_mt" {
  count           = length(aws_subnet.private_subnets)
  file_system_id  = aws_efs_file_system.cloudbeaver_tm_data.id
  subnet_id       = aws_subnet.private_subnets[count.index].id
  security_groups = [aws_security_group.dbeaver_efs.id]
}

resource "aws_efs_file_system" "cloudbeaver_dc_data" {
  creation_token  = "${var.environment}-cloudbeaver_dc_data"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags = {
    Env  = var.environment
    Name = "DBeaver TE DC DATA EFS"
  }
}

resource "aws_efs_mount_target" "cloudbeaver_dc_data_mt" {
  count           = length(aws_subnet.private_subnets)
  file_system_id  = aws_efs_file_system.cloudbeaver_dc_data.id
  subnet_id       = aws_subnet.private_subnets[count.index].id
  security_groups = [aws_security_group.dbeaver_efs.id]
}


################################################################################
# Postgres
################################################################################

resource "aws_ecs_task_definition" "dbeaver_db" {

  depends_on = [
   aws_ecs_cluster.dbeaver_te
  ]
  count                    = var.rds_db ? 0 : 1
  family                   = "${var.environment}-DBeaverTeamEdition-db"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  volume {
    name      = "${var.environment}-cloudbeaver_db_data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.cloudbeaver_db_data.id
      root_directory = "/"
    }
  }
  container_definitions = jsonencode([{
    name        = "${var.environment}-postgres"
    image       = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/cloudbeaver-postgres:16"
    essential   = true
    environment = var.cloudbeaver-db-env
    mountPoints = [{
              "containerPath": "/var/lib/postgresql/data",
              "sourceVolume": "${var.environment}-cloudbeaver_db_data"
    }]
    logConfiguration = {
                "logDriver": "awslogs"
                "options": {
                    "awslogs-group": "${var.environment}-DBeaverTeamEdition",
                    "awslogs-region": "${var.aws_region}",
                    "awslogs-create-group": "true",
                    "awslogs-stream-prefix": "db"
                }
    }
    portMappings = [{
      name = "${var.environment}-postgres"
      protocol      = "tcp"
      containerPort = 5432
      hostPort      = 5432
    }]
  }])
}

resource "aws_ecs_service" "postgres" {

  depends_on = [
    aws_ecs_task_definition.dbeaver_db[0],
    aws_security_group.dbeaver_te_private
  ]
  count           = var.rds_db ? 0 : 1
  name            = "${var.environment}-postgres"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_db[0].arn
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
      port_name = "${var.environment}-postgres"
      client_alias {
        dns_name = "${var.environment}-postgres"
        port     = 5432
      }

    }
  }

  tags = {
    Env  = var.environment
    Name = "DBeaver TE DC DATA EFS"
  }
}

################################################################################
# Kafka
################################################################################

resource "aws_ecs_task_definition" "kafka" {

  depends_on = [
   aws_ecs_cluster.dbeaver_te
  ]

  family                   = "${var.environment}-DBeaverTeamEdition-kafka"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = jsonencode([{
    name        = "${var.environment}-kafka"
    image       = "dbeaver/cloudbeaver-kafka:3.8"
    essential   = true
    environment = var.cloudbeaver-kafka-env
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "${var.environment}-DBeaverTeamEdition"
        awslogs-region        = "${var.aws_region}"
        awslogs-create-group  = "true"
        awslogs-stream-prefix = "kafka"
      }
    }
    portMappings = [{
      name          = "${var.environment}-kafka"
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

  name            = "${var.environment}-kafka"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.kafka.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    security_groups = [aws_security_group.dbeaver_te_private.id]
    subnets         = aws_subnet.private_subnets[*].id
    assign_public_ip = false
  }
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "${var.environment}-kafka"
      client_alias {
        dns_name = "${var.environment}-kafka"
        port     = 9092
      }

    }
  }
  tags = {
    Env  = var.environment
    Name = "DBeaverTeamEdition-kafka"
  }
}



################################################################################
# DBeaver TE DC
################################################################################


resource "aws_ecs_task_definition" "dbeaver_dc" { 

  depends_on = [
   aws_ecs_cluster.dbeaver_te
  ]

  family                   = "${var.environment}-DBeaverTeamEdition-dc"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  volume {
    name      = "${var.environment}-cloudbeaver_dc_data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.cloudbeaver_dc_data.id
      root_directory = "/"
    }
  }
  container_definitions = jsonencode([{
    name        = "${var.environment}-cloudbeaver-dc"
    image       = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/cloudbeaver-dc:${var.dbeaver_te_version}"
    essential   = true
    environment = local.updated_cloudbeaver_dc_env
    mountPoints = [{
      containerPath = "/opt/domain-controller/workspace"
      sourceVolume  = "${var.environment}-cloudbeaver_dc_data"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "${var.environment}-DBeaverTeamEdition"
        awslogs-region        = "${var.aws_region}"
        awslogs-create-group  = "true"
        awslogs-stream-prefix = "dc"
      }
    }
    portMappings = [{
      name          = "${var.environment}-cloudbeaver-dc"
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

  name            = "${var.environment}-cloudbeaver-dc"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_dc.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    security_groups = [aws_security_group.dbeaver_te.id]
    subnets         = aws_subnet.private_subnets[*].id
    assign_public_ip = false
  }
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "${var.environment}-cloudbeaver-dc"
      client_alias {
        dns_name = "${var.environment}-cloudbeaver-dc"
        port     = 8970
      }
    }
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.dbeaver_dc.arn
    container_name   = "${var.environment}-cloudbeaver-dc"
    container_port   = 8970
  }

  tags = {
    Env  = var.environment
    Name = "DBeaverTeamEdition-dc"
  }
}

################################################################################
# DBeaver TE RM
################################################################################

resource "aws_ecs_task_definition" "dbeaver_rm" {

  depends_on = [
   aws_ecs_cluster.dbeaver_te,
   aws_ecs_task_definition.dbeaver_dc
  ]

  family                   = "${var.environment}-DBeaverTeamEdition-rm"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  volume {
    name      = "${var.environment}-cloudbeaver_rm_data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.cloudbeaver_rm_data.id
      root_directory = "/"
    }
  }
  container_definitions = jsonencode([{
    name        = "${var.environment}-cloudbeaver-rm"
    image       = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/cloudbeaver-rm:${var.dbeaver_te_version}"
    essential   = true
    environment = var.cloudbeaver-shared-env
    mountPoints = [{
      containerPath = "/opt/resource-manager/workspace"
      sourceVolume  = "${var.environment}-cloudbeaver_rm_data"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "${var.environment}-DBeaverTeamEdition"
        awslogs-region        = "${var.aws_region}"
        awslogs-create-group  = "true"
        awslogs-stream-prefix = "rm"
      }
    }
    portMappings = [{
      name          = "${var.environment}-cloudbeaver-rm"
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

  name            = "${var.environment}-cloudbeaver-rm"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_rm.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    security_groups = [aws_security_group.dbeaver_te.id]
    subnets         = aws_subnet.private_subnets[*].id
    assign_public_ip = false
  }
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "${var.environment}-cloudbeaver-rm"
      client_alias {
        dns_name = "${var.environment}-cloudbeaver-rm"
        port     = 8971
      }
    }
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.dbeaver_rm.arn
    container_name   = "${var.environment}-cloudbeaver-rm"
    container_port   = 8971
  }

  tags = {
    Env  = var.environment
    Name = "DBeaverTeamEdition-rm"
  }
}

################################################################################
# DBeaver TE QM
################################################################################

resource "aws_ecs_task_definition" "dbeaver_qm" {

  depends_on = [
   aws_ecs_cluster.dbeaver_te,
   aws_ecs_task_definition.dbeaver_dc
  ]

  family                   = "${var.environment}-DBeaverTeamEdition-qm"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  container_definitions = jsonencode([{
    name        = "${var.environment}-cloudbeaver-qm"
    image       = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/cloudbeaver-qm:${var.dbeaver_te_version}"
    essential   = true
    environment = var.cloudbeaver-shared-env
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "${var.environment}-DBeaverTeamEdition"
        awslogs-region        = "${var.aws_region}"
        awslogs-create-group  = "true"
        awslogs-stream-prefix = "qm"
      }
    }
    portMappings = [{
      name          = "${var.environment}-cloudbeaver-qm"
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

  name            = "${var.environment}-cloudbeaver-qm"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_qm.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    security_groups = [aws_security_group.dbeaver_te.id]
    subnets         = aws_subnet.private_subnets[*].id
    assign_public_ip = false
  }
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "${var.environment}-cloudbeaver-qm"
      client_alias {
        dns_name = "${var.environment}-cloudbeaver-qm"
        port     = 8972
      }
    }
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.dbeaver_qm.arn
    container_name   = "${var.environment}-cloudbeaver-qm"
    container_port   = 8972
  }

  tags = {
    Env  = var.environment
    Name = "DBeaverTeamEdition-qm"
  }
}


################################################################################
# DBeaver TE TM
################################################################################

resource "aws_ecs_task_definition" "dbeaver_tm" {

  depends_on = [
   aws_ecs_cluster.dbeaver_te,
   aws_ecs_task_definition.dbeaver_rm,
   aws_ecs_task_definition.dbeaver_dc
  ]

  family                   = "${var.environment}-DBeaverTeamEdition-tm"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  volume {
    name      = "${var.environment}-cloudbeaver_tm_data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.cloudbeaver_tm_data.id
      root_directory = "/"
    }
  }
  container_definitions = jsonencode([{
    name        = "${var.environment}-cloudbeaver-tm"
    image       = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/cloudbeaver-tm:${var.dbeaver_te_version}"
    essential   = true
    environment = var.cloudbeaver-shared-env
    mountPoints = [{
      containerPath = "/opt/task-manager/workspace"
      sourceVolume  = "${var.environment}-cloudbeaver_tm_data"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "${var.environment}-DBeaverTeamEdition"
        awslogs-region        = "${var.aws_region}"
        awslogs-create-group  = "true"
        awslogs-stream-prefix = "tm"
      }
    }
    portMappings = [{
      name          = "${var.environment}-cloudbeaver-tm"
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

  name            = "${var.environment}-cloudbeaver-tm"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_tm.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    security_groups = [aws_security_group.dbeaver_te.id]
    subnets         = aws_subnet.private_subnets[*].id
    assign_public_ip = false
  }
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "${var.environment}-cloudbeaver-tm"
      client_alias {
        dns_name = "${var.environment}-cloudbeaver-tm"
        port     = 8973
      }
    }
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.dbeaver_tm.arn
    container_name   = "${var.environment}-cloudbeaver-tm"
    container_port   = 8973
  }

  tags = {
    Env  = var.environment
    Name = "DBeaverTeamEdition-tm"
  }
}

################################################################################
# DBeaver TE CloudBeaver
################################################################################

resource "aws_ecs_task_definition" "dbeaver_te" {

  depends_on = [
   aws_ecs_cluster.dbeaver_te,
   aws_ecs_task_definition.dbeaver_dc,
   aws_ecs_task_definition.dbeaver_rm
  ]

  family                   = "${var.environment}-DBeaverTeamEdition-te"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 4096
  memory                   = 8192
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = jsonencode([{
    name        = "${var.environment}-cloudbeaver-te"
    image       = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/cloudbeaver-te:${var.dbeaver_te_version}"
    essential   = true
    environment = var.cloudbeaver-shared-env
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "${var.environment}-DBeaverTeamEdition"
        awslogs-region        = "${var.aws_region}"
        awslogs-create-group  = "true"
        awslogs-stream-prefix = "te"
      }
    }
    portMappings = [{
      name          = "${var.environment}-cloudbeaver-te"
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

  name            = "${var.environment}-cloudbeaver-te"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_te.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    security_groups = [aws_security_group.dbeaver_te.id]
    subnets         = aws_subnet.private_subnets[*].id
    assign_public_ip = false
  }
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "${var.environment}-cloudbeaver-te"
      client_alias {
        dns_name = "${var.environment}-cloudbeaver-te"
        port     = 8978
      }
    }
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.dbeaver_te.arn
    container_name   = "${var.environment}-cloudbeaver-te"
    container_port   = 8978
  }

  tags = {
    Env  = var.environment
    Name = "${var.environment}-DBeaverTeamEdition-te"
  }
}
