################################################################################
# Postgres (container-based, disabled when var.rds_db = true)
################################################################################

module "postgres" {
  source = "./modules/ecs-service"
  count  = var.rds_db ? 0 : 1

  name                    = "postgres"
  name_prefix             = local.name_prefix
  name_prefix_full        = local.name_prefix_full
  family_suffix           = "db"
  log_prefix              = "db"
  deployment_id           = var.deployment_id
  container_name_override = "${var.deployment_id}-postgres"
  image                   = "${var.image_source}/cloudbeaver-postgres:16"
  cpu                     = 256
  memory                  = 512
  container_port          = 5432

  execution_role_arn = module.iam.execution_role_arn

  environment = var.cloudbeaver-db-env

  efs_volumes = [
    {
      name           = "cloudbeaver_db_data"
      file_system_id = module.efs["db_data"].file_system_id
      root_directory = "/"
      mount_path     = "/var/lib/postgresql/data"
    }
  ]

  cluster_id                    = module.ecs_cluster.id
  security_group_ids            = [aws_security_group.dbeaver_te_private.id]
  subnet_ids                    = local.private_subnets
  service_connect_namespace_arn = aws_service_discovery_private_dns_namespace.dbeaver.arn
  desired_count                 = 1
  enable_execute_command        = false

  aws_region     = var.aws_region
  log_group_name = local.log_group_name

  tags = { Env = var.deployment_id }
}
