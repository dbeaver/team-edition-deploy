################################################################################
# DBeaver TE DC
################################################################################

module "cloudbeaver_dc_route" {
  source = "./modules/alb-route"

  name              = "${local.name_prefix}-${var.deployment_id}-dc"
  vpc_id            = local.vpc_id
  listener_arn      = module.alb.https_listener_arn
  path_pattern      = "/dc*"
  priority          = 99
  health_check_path = "/dc/health"

  tags = { Env = var.deployment_id }
}

module "cloudbeaver_dc" {
  source = "./modules/ecs-service"

  name             = "cloudbeaver-dc"
  name_prefix      = local.name_prefix
  name_prefix_full = local.name_prefix_full
  family_suffix    = "dc"
  deployment_id    = var.deployment_id
  image            = "${var.image_source}/cloudbeaver-dc:${var.dbeaver_te_version}"
  cpu              = 1024
  memory           = 2048
  container_port   = 8970

  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  environment        = local.updated_cloudbeaver_dc_env

  efs_volumes = [
    {
      name           = "cloudbeaver_dc_data"
      file_system_id = module.efs["dc_data"].file_system_id
      root_directory = "/"
      mount_path     = "/opt/domain-controller/workspace"
    },
    {
      name               = "cloudbeaver_certificates"
      file_system_id     = module.efs["certificates"].file_system_id
      root_directory     = "/"
      transit_encryption = true
      mount_path         = "/opt/domain-controller/conf/certificates"
    },
    {
      name               = "api_tokens"
      file_system_id     = module.efs["api_tokens"].file_system_id
      root_directory     = "/"
      transit_encryption = true
      mount_path         = "/opt/domain-controller/conf/keys"
    }
  ]

  cluster_id                    = module.ecs_cluster.id
  security_group_ids            = [aws_security_group.dbeaver_te.id]
  subnet_ids                    = local.private_subnets
  service_connect_namespace_arn = aws_service_discovery_private_dns_namespace.dbeaver.arn
  desired_count                 = var.desired_count["dc"]
  enable_execute_command        = true

  target_group_arn = module.cloudbeaver_dc_route.target_group_arn

  aws_region     = var.aws_region
  log_group_name = local.log_group_name

  tags = { Env = var.deployment_id }

  depends_on = [module.kafka, module.rds, module.postgres]
}
