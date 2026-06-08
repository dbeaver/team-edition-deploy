resource "aws_ecs_cluster" "this" {
  name = var.name

  dynamic "setting" {
    for_each = var.container_insights_enabled ? [1] : []
    content {
      name  = "containerInsights"
      value = "enabled"
    }
  }

  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = var.capacity_providers

  default_capacity_provider_strategy {
    base              = var.default_capacity_provider_base
    weight            = var.default_capacity_provider_weight
    capacity_provider = var.default_capacity_provider
  }
}
