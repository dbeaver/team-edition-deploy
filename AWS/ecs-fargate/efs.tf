################################################################################
# EFS Volumes
################################################################################

module "efs" {
  source   = "./modules/efs-volume"
  for_each = local.efs_volumes

  name               = each.value.name
  deployment_id      = var.deployment_id
  name_prefix        = local.name_prefix
  subnet_ids         = local.private_subnets
  security_group_ids = [aws_security_group.dbeaver_efs.id]
  encrypted          = var.efs_encrypted

  access_point = lookup(each.value, "access_point", null)

  tags = {
    Env = var.deployment_id
  }
}
