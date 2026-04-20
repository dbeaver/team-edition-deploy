################################################################################
# VPC (optional, created when var.create_vpc = true)
################################################################################

module "vpc" {
  source = "./modules/vpc"

  count = var.create_vpc ? 1 : 0

  name                 = local.name_prefix_full
  cidr                 = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  tags = {
    Env = var.deployment_id
  }
}
