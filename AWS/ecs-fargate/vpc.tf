data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.deployment_id}-dbeaver-te"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  map_public_ip_on_launch = true

  public_subnet_tags = {
    Env = var.deployment_id
  }

  private_subnet_tags = {
    Env = var.deployment_id
  }

  tags = {
    Env  = var.deployment_id
    Name = "DBeaverTeamEdition"
  }
}
