################################################################################
# DBeaver TE TM
################################################################################

module "cloudbeaver_tm_route" {
  source = "./modules/alb-route"

  name              = "${local.name_prefix}-${var.deployment_id}-tm"
  vpc_id            = local.vpc_id
  listener_arn      = module.alb.https_listener_arn
  path_pattern      = "/tm*"
  priority          = 94
  health_check_path = "/tm/health"

  tags = { Env = var.deployment_id }
}

module "cloudbeaver_tm" {
  source = "./modules/ecs-service"

  name             = "cloudbeaver-tm"
  name_prefix      = local.name_prefix
  name_prefix_full = local.name_prefix_full
  family_suffix    = "tm"
  deployment_id    = var.deployment_id
  image            = "${var.image_source}/cloudbeaver-tm:${var.dbeaver_te_version}"
  cpu              = 2048
  memory           = 4096
  container_port   = 8973

  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  environment        = local.cloudbeaver_shared_env_modified

  efs_volumes = [
    {
      name           = "cloudbeaver_tm_data"
      file_system_id = module.efs["tm_data"].file_system_id
      root_directory = "/"
      mount_path     = "/opt/task-manager/workspace"
    },
    {
      name               = "cloudbeaver_certificates_public"
      file_system_id     = module.efs["certificates"].file_system_id
      access_point_id    = module.efs["certificates"].access_point_id
      mount_path         = "/opt/task-manager/conf/certificates"
      transit_encryption = true
    }
  ]

  cluster_id                    = module.ecs_cluster.id
  security_group_ids            = [aws_security_group.dbeaver_te.id]
  subnet_ids                    = local.private_subnets
  service_connect_namespace_arn = aws_service_discovery_private_dns_namespace.dbeaver.arn
  desired_count                 = var.desired_count["tm"]
  enable_execute_command        = true

  target_group_arn = module.cloudbeaver_tm_route.target_group_arn

  aws_region     = var.aws_region
  log_group_name = local.log_group_name

  tags = { Env = var.deployment_id }

  depends_on = [module.cloudbeaver_dc]
}
