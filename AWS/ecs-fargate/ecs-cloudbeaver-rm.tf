################################################################################
# DBeaver TE RM
################################################################################

module "cloudbeaver_rm_route" {
  source = "./modules/alb-route"

  name              = "${local.name_prefix}-${var.deployment_id}-rm"
  vpc_id            = local.vpc_id
  listener_arn      = module.alb.https_listener_arn
  path_pattern      = "/rm*"
  priority          = 97
  health_check_path = "/rm/health"

  tags = { Env = var.deployment_id }
}

module "cloudbeaver_rm" {
  source = "./modules/ecs-service"

  name             = "cloudbeaver-rm"
  name_prefix      = local.name_prefix
  name_prefix_full = local.name_prefix_full
  family_suffix    = "rm"
  deployment_id    = var.deployment_id
  image            = "${var.image_source}/cloudbeaver-rm:${var.dbeaver_te_version}"
  cpu              = 1024
  memory           = 2048
  container_port   = 8971

  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  environment        = local.cloudbeaver_shared_env_modified

  efs_volumes = [
    {
      name           = "cloudbeaver_rm_data"
      file_system_id = module.efs["rm_data"].file_system_id
      root_directory = "/"
      mount_path     = "/opt/resource-manager/workspace"
    },
    {
      name               = "cloudbeaver_certificates_public"
      file_system_id     = module.efs["certificates"].file_system_id
      access_point_id    = module.efs["certificates"].access_point_id
      mount_path         = "/opt/resource-manager/conf/certificates"
      transit_encryption = true
    }
  ]

  cluster_id                    = module.ecs_cluster.id
  security_group_ids            = [aws_security_group.dbeaver_te.id]
  subnet_ids                    = local.private_subnets
  service_connect_namespace_arn = aws_service_discovery_private_dns_namespace.dbeaver.arn
  desired_count                 = var.desired_count["rm"]
  enable_execute_command        = true

  target_group_arn = module.cloudbeaver_rm_route.target_group_arn

  aws_region     = var.aws_region
  log_group_name = local.log_group_name

  tags = { Env = var.deployment_id }

  depends_on = [module.cloudbeaver_dc]
}
