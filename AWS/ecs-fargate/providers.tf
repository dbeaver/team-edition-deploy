provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project    = local.name_prefix_full
      Deployment = var.deployment_id
      ManagedBy  = "terraform"
    }
  }
}
