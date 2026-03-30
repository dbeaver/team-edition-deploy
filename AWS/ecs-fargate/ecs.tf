################################################################################
# ECS Cluster
################################################################################

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 5.0"

  cluster_name = "DBeaverTeamEdition-${var.deployment_id}"

  create_cloudwatch_log_group = false

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 1
        base   = 1
      }
    }
  }

  tags = {
    Env = var.deployment_id
  }
}

resource "aws_service_discovery_private_dns_namespace" "dbeaver" {
  name        = "${var.deployment_id}-${var.dbeaver_te_default_ns}"
  description = "DBeaver SD Namespace"
  vpc         = module.vpc.vpc_id
}
