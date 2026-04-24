################################################################################
# ECS Cluster
################################################################################

module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  name = "${local.name_prefix_full}-${var.deployment_id}"

  capacity_providers               = ["FARGATE"]
  default_capacity_provider        = "FARGATE"
  default_capacity_provider_base   = 1
  default_capacity_provider_weight = 1

  tags = {
    Env = var.deployment_id
  }
}

resource "aws_service_discovery_private_dns_namespace" "dbeaver" {
  name        = "${var.deployment_id}-${var.dbeaver_te_default_ns}"
  description = "DBeaver SD Namespace"
  vpc         = local.vpc_id
}
