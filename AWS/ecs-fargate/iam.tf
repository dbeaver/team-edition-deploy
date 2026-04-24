################################################################################
# IAM Roles
################################################################################

module "iam" {
  source = "./modules/iam"

  deployment_id    = var.deployment_id
  name_prefix      = local.name_prefix
  name_prefix_full = local.name_prefix_full
  efs_arns         = [for k, v in module.efs : v.file_system_arn]
  efs_ap_arns      = compact([for k, v in module.efs : v.access_point_arn != null ? v.access_point_arn : ""])

  tags = {
    Env = var.deployment_id
  }
}
