################################################################################
# Kafka
################################################################################

module "kafka" {
  source = "./modules/ecs-service"

  name             = "kafka"
  name_prefix      = local.name_prefix
  name_prefix_full = local.name_prefix_full
  deployment_id    = var.deployment_id
  image            = "${var.image_source}/cloudbeaver-kafka:3.9"
  cpu              = 2048
  memory           = 4096
  container_port   = 9092

  execution_role_arn = module.iam.execution_role_arn

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
