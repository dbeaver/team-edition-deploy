provider "aws" {
  region = var.aws_region
}

resource "aws_ecs_cluster" "dbeaver_te" {
  name = "DBeaverTeamEdition-${var.deployment_id}"
}

locals {

  rds_db_url = length(aws_db_instance.rds_dbeaver_db) > 0 ? "jdbc:postgresql://${try(aws_db_instance.rds_dbeaver_db[0].address, "")}:5432/cloudbeaver" : ""

  cloudbeaver_dc_env_modified = [
    for item in var.cloudbeaver-dc-env : {
      name  = item.name
      value = (
        item.name == "CLOUDBEAVER_DC_BACKEND_DB_URL" ? (var.rds_db ? local.rds_db_url : format("jdbc:postgresql://%s-postgres:5432/cloudbeaver", var.deployment_id)) :
        item.name == "CLOUDBEAVER_QM_BACKEND_DB_URL" ? (var.rds_db ? local.rds_db_url : format("jdbc:postgresql://%s-postgres:5432/cloudbeaver", var.deployment_id)) :
        item.name == "CLOUDBEAVER_TM_BACKEND_DB_URL" ? (var.rds_db ? local.rds_db_url : format("jdbc:postgresql://%s-postgres:5432/cloudbeaver", var.deployment_id)) :
        item.name == "CLOUDBEAVER_DC_SERVER_URL" ? format("http://%s-cloudbeaver-dc:8970/dc", var.deployment_id) :
        item.name == "CLOUDBEAVER_QM_SERVER_URL" ? format("http://%s-cloudbeaver-qm:8972/qm", var.deployment_id) :
        item.name == "CLOUDBEAVER_RM_SERVER_URL" ? format("http://%s-cloudbeaver-rm:8971/rm", var.deployment_id) :
        item.name == "CLOUDBEAVER_TM_SERVER_URL" ? format("http://%s-cloudbeaver-tm:8973/tm", var.deployment_id) :
        item.value
      )
    }
  ]

  cloudbeaver_shared_env_modified = [
    for item in var.cloudbeaver-shared-env : {
      name  = item.name
      value = (
        item.name == "CLOUDBEAVER_DC_SERVER_URL" ? format("http://%s-cloudbeaver-dc:8970/dc", var.deployment_id) :
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
  name        = "${var.deployment_id}-${var.dbeaver_te_default_ns}"
  description = "DBeaver SD Namespace"
  vpc         = aws_vpc.dbeaver_net.id
}


################################################################################
# EFS
################################################################################

resource "aws_efs_file_system" "cloudbeaver_db_data" {
  creation_token  = "${var.deployment_id}-cloudbeaver_db_data"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags = {
    Env  = var.deployment_id
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
  creation_token  = "${var.deployment_id}-cloudbeaver_rm_data"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags = {
    Env  = var.deployment_id
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
  creation_token   = "${var.deployment_id}-cloudbeaver_tm_data"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags = {
    Env  = var.deployment_id
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
  creation_token   = "${var.deployment_id}-cloudbeaver_dc_data"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags = {
    Env  = var.deployment_id
    Name = "DBeaver TE DC DATA EFS"
  }
}

resource "aws_efs_mount_target" "cloudbeaver_dc_data_mt" {
  count           = length(aws_subnet.private_subnets)
  file_system_id  = aws_efs_file_system.cloudbeaver_dc_data.id
  subnet_id       = aws_subnet.private_subnets[count.index].id
  security_groups = [aws_security_group.dbeaver_efs.id]
}

resource "aws_efs_file_system" "cloudbeaver_certificates" {
  creation_token   = "${var.deployment_id}-cloudbeaver_certificates"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags = {
    Env  = var.deployment_id
    Name = "DBeaver TE CERTIFICATES EFS"
  }
}

resource "aws_efs_access_point" "certs_public" {
  file_system_id = aws_efs_file_system.cloudbeaver_certificates.id
  root_directory {
    path = "/public"

    creation_info {
      owner_uid   = 8978          
      owner_gid   = 8978
      permissions = "0755"        
    }
  }

  posix_user {
    uid = 8978
    gid = 8978
  }

  tags = {
    Env  = var.deployment_id
    Name = "DBeaver TE PUBLIC CERTIFICATES MOUNTPOINT EFS"
  }
}

resource "aws_efs_file_system" "api_tokens" {
  creation_token   = "${var.deployment_id}-api_tokens"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags = {
    Env  = var.deployment_id
    Name = "DBeaver TE API TOKENS EFS"
  }
}
resource "aws_efs_mount_target" "cloudbeaver_certificates_mt" {
  count           = length(aws_subnet.private_subnets)
  file_system_id  = aws_efs_file_system.cloudbeaver_certificates.id
  subnet_id       = aws_subnet.private_subnets[count.index].id
  security_groups = [aws_security_group.dbeaver_efs.id]
}

resource "aws_efs_mount_target" "api_tokens_mt" {
  count           = length(aws_subnet.private_subnets)
  file_system_id  = aws_efs_file_system.api_tokens.id
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
  family                   = "DBeaverTeamEdition-${var.deployment_id}-db"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  volume {
    name      = "${var.deployment_id}-cloudbeaver_db_data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.cloudbeaver_db_data.id
      root_directory = "/"
    }
  }
  container_definitions = jsonencode([{
    name        = "${var.deployment_id}-postgres"
    image       = "dbeaver/cloudbeaver-postgres:16"
    essential   = true
    environment = var.cloudbeaver-db-env
    mountPoints = [{
              "containerPath": "/var/lib/postgresql/data",
              "sourceVolume": "${var.deployment_id}-cloudbeaver_db_data"
    }]
    logConfiguration = {
                "logDriver": "awslogs"
                "options": {
                    "awslogs-group": "DBeaverTeamEdition-${var.deployment_id}",
                    "awslogs-region": "${var.aws_region}",
                    "awslogs-create-group": "true",
                    "awslogs-stream-prefix": "db"
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

  depends_on = [
    aws_ecs_task_definition.dbeaver_db[0],
    aws_security_group.dbeaver_te_private
  ]
  count           = var.rds_db ? 0 : 1
  name            = "${var.deployment_id}-postgres"
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
      port_name = "${var.deployment_id}-postgres"
      client_alias {
        dns_name = "${var.deployment_id}-postgres"
        port     = 5432
      }

    }
  }

  tags = {
    Env  = var.deployment_id
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

  family                   = "DBeaverTeamEdition-${var.deployment_id}-kafka"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = jsonencode([{
    name        = "${var.deployment_id}-kafka"
    image       = "dbeaver/cloudbeaver-kafka:3.9"
    essential   = true
    environment = var.cloudbeaver-kafka-env
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "DBeaverTeamEdition-${var.deployment_id}"
        awslogs-region        = "${var.aws_region}"
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

  depends_on = [
    aws_ecs_task_definition.kafka,
    aws_security_group.dbeaver_te_private
  ]

  name            = "${var.deployment_id}-kafka"
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
      port_name  = "${var.deployment_id}-kafka"
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



################################################################################
# DBeaver TE DC
################################################################################


resource "aws_ecs_task_definition" "dbeaver_dc" { 

  depends_on = [
   aws_ecs_cluster.dbeaver_te
  ]

  family                   = "DBeaverTeamEdition-${var.deployment_id}-dc"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn = aws_iam_role.ecs_task_role_exec.arn

  volume {
    name      = "${var.deployment_id}-cloudbeaver_dc_data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.cloudbeaver_dc_data.id
      root_directory = "/"
    }
  }
  volume {
    name = "${var.deployment_id}-cloudbeaver_certificates"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.cloudbeaver_certificates.id
      root_directory = "/"
      transit_encryption = "ENABLED"
    }
  }
  volume {
    name = "${var.deployment_id}-api_tokens"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.api_tokens.id
      root_directory = "/"
      transit_encryption = "ENABLED"
    }
  }
  container_definitions = jsonencode([{
    name        = "${var.deployment_id}-cloudbeaver-dc"
    image       = "dbeaver/cloudbeaver-dc:${var.dbeaver_te_version}"
    essential   = true
    environment = local.updated_cloudbeaver_dc_env
    mountPoints = [{
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
        awslogs-region        = "${var.aws_region}"
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

  depends_on = [
    aws_ecs_task_definition.dbeaver_dc,
    aws_security_group.dbeaver_te
  ]

  name            = "${var.deployment_id}-cloudbeaver-dc"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_dc.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count["dc"]
  enable_execute_command = true

  network_configuration {
    security_groups = [aws_security_group.dbeaver_te.id]
    subnets         = aws_subnet.private_subnets[*].id
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

################################################################################
# DBeaver TE RM
################################################################################

resource "aws_ecs_task_definition" "dbeaver_rm" {

  depends_on = [
   aws_ecs_cluster.dbeaver_te,
   aws_ecs_task_definition.dbeaver_dc
  ]

  family                   = "DBeaverTeamEdition-${var.deployment_id}-rm"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn = aws_iam_role.ecs_task_role_exec.arn

  volume {
    name      = "${var.deployment_id}-cloudbeaver_rm_data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.cloudbeaver_rm_data.id
      root_directory = "/"
    }
  }
  volume {
    name      = "${var.deployment_id}-cloudbeaver_certificates_public"
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
    image       = "dbeaver/cloudbeaver-rm:${var.dbeaver_te_version}"
    essential   = true
    environment = local.cloudbeaver_shared_env_modified
    mountPoints = [{
      containerPath = "/opt/resource-manager/workspace"
      sourceVolume  = "${var.deployment_id}-cloudbeaver_rm_data"
    },
    {
      containerPath = "/opt/resource-manager/conf/certificates"
      sourceVolume  = "${var.deployment_id}-cloudbeaver_certificates_public"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "DBeaverTeamEdition-${var.deployment_id}"
        awslogs-region        = "${var.aws_region}"
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

  depends_on = [
    aws_ecs_task_definition.dbeaver_rm,
    aws_security_group.dbeaver_te
  ]

  name            = "${var.deployment_id}-cloudbeaver-rm"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_rm.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count["rm"]
  enable_execute_command = true

  network_configuration {
    security_groups = [aws_security_group.dbeaver_te.id]
    subnets         = aws_subnet.private_subnets[*].id
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

################################################################################
# DBeaver TE QM
################################################################################

resource "aws_ecs_task_definition" "dbeaver_qm" {

  depends_on = [
   aws_ecs_cluster.dbeaver_te,
   aws_ecs_task_definition.dbeaver_dc
  ]

  family                   = "DBeaverTeamEdition-${var.deployment_id}-qm"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn = aws_iam_role.ecs_task_role_exec.arn
  volume {
    name      = "${var.deployment_id}-cloudbeaver_certificates_public"
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
    name        = "${var.deployment_id}-cloudbeaver-qm"
    image       = "dbeaver/cloudbeaver-qm:${var.dbeaver_te_version}"
    essential   = true
    environment = local.cloudbeaver_shared_env_modified
    mountPoints = [
    {
      containerPath = "/opt/query-manager/conf/certificates"
      sourceVolume  = "${var.deployment_id}-cloudbeaver_certificates_public"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "DBeaverTeamEdition-${var.deployment_id}"
        awslogs-region        = "${var.aws_region}"
        awslogs-create-group  = "true"
        awslogs-stream-prefix = "qm"
      }
    }
    portMappings = [{
      name          = "${var.deployment_id}-cloudbeaver-qm"
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

  name            = "${var.deployment_id}-cloudbeaver-qm"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_qm.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count["qm"]
  enable_execute_command = true

  network_configuration {
    security_groups  = [aws_security_group.dbeaver_te.id]
    subnets          = aws_subnet.private_subnets[*].id
    assign_public_ip = false
  }
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "${var.deployment_id}-cloudbeaver-qm"
      client_alias {
        dns_name = "${var.deployment_id}-cloudbeaver-qm"
        port     = 8972
      }
    }
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.dbeaver_qm.arn
    container_name   = "${var.deployment_id}-cloudbeaver-qm"
    container_port   = 8972
  }

  tags = {
    Env  = var.deployment_id
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

  family                   = "DBeaverTeamEdition-${var.deployment_id}-tm"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn = aws_iam_role.ecs_task_role_exec.arn

  volume {
    name      = "${var.deployment_id}-cloudbeaver_tm_data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.cloudbeaver_tm_data.id
      root_directory = "/"
    }
  }
  volume {
    name      = "${var.deployment_id}-cloudbeaver_certificates_public"
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
    image       = "dbeaver/cloudbeaver-tm:${var.dbeaver_te_version}"
    essential   = true
    environment = local.cloudbeaver_shared_env_modified
    mountPoints = [{
      containerPath = "/opt/task-manager/workspace"
      sourceVolume  = "${var.deployment_id}-cloudbeaver_tm_data"
    },
    {
      containerPath = "/opt/task-manager/conf/certificates"
      sourceVolume  = "${var.deployment_id}-cloudbeaver_certificates_public"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "DBeaverTeamEdition-${var.deployment_id}"
        awslogs-region        = "${var.aws_region}"
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

  depends_on = [
    aws_ecs_task_definition.dbeaver_tm,
    aws_security_group.dbeaver_te
  ]

  name            = "${var.deployment_id}-cloudbeaver-tm"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_tm.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count["tm"]
  enable_execute_command = true

  network_configuration {
    security_groups  = [aws_security_group.dbeaver_te.id]
    subnets          = aws_subnet.private_subnets[*].id
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

################################################################################
# DBeaver TE CloudBeaver
################################################################################

resource "aws_ecs_task_definition" "dbeaver_te" {

  depends_on = [
   aws_ecs_cluster.dbeaver_te,
   aws_ecs_task_definition.dbeaver_dc,
   aws_ecs_task_definition.dbeaver_rm
  ]

  family                   = "DBeaverTeamEdition-${var.deployment_id}-te"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 4096
  memory                   = 8192
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn = aws_iam_role.ecs_task_role_exec.arn


  volume {
    name      = "${var.deployment_id}-cloudbeaver_certificates_public"
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
    name        = "${var.deployment_id}-cloudbeaver-te"
    image       = "dbeaver/cloudbeaver-te:${var.dbeaver_te_version}"
    essential   = true
    environment = local.cloudbeaver_shared_env_modified
    mountPoints = [{
      containerPath = "/opt/cloudbeaver/conf/certificates"         
      sourceVolume  = "${var.deployment_id}-cloudbeaver_certificates_public"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "DBeaverTeamEdition-${var.deployment_id}"
        awslogs-region        = "${var.aws_region}"
        awslogs-create-group  = "true"
        awslogs-stream-prefix = "te"
      }
    }
    portMappings = [{
      name          = "${var.deployment_id}-cloudbeaver-te"
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

  name            = "${var.deployment_id}-cloudbeaver-te"
  cluster         = aws_ecs_cluster.dbeaver_te.id
  task_definition = aws_ecs_task_definition.dbeaver_te.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count["te"]
  enable_execute_command = true

  network_configuration {
    security_groups = [aws_security_group.dbeaver_te.id]
    subnets         = aws_subnet.private_subnets[*].id
    assign_public_ip = false
  }
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.dbeaver.arn
    service {
      port_name = "${var.deployment_id}-cloudbeaver-te"
      client_alias {
        dns_name = "${var.deployment_id}-cloudbeaver-te"
        port     = 8978
      }
    }
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.dbeaver_te.arn
    container_name   = "${var.deployment_id}-cloudbeaver-te"
    container_port   = 8978
  }

  tags = {
    Env  = var.deployment_id
    Name = "DBeaverTeamEdition-${var.deployment_id}-te"
  }
}
