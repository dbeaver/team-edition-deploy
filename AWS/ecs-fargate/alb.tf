################################################################################
# AWS ALB
################################################################################

module "alb" {
  source = "./modules/alb"

  name               = "${local.name_prefix}-${var.deployment_id}-ALB"
  deployment_id      = var.deployment_id
  vpc_id             = local.vpc_id
  public_subnets     = local.public_subnets
  security_group_ids = [aws_security_group.dbeaver_alb.id]
  certificate_arn    = "arn:aws:acm:${var.aws_region}:${var.aws_account_id}:certificate/${var.alb_certificate_Identifier}"
  ssl_policy         = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  tags = {
    Env = var.deployment_id
  }
}
