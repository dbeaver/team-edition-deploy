################################################################################
# RDS PostgreSQL (optional, enabled via var.rds_db)
################################################################################

module "rds" {
  source = "./modules/rds"

  count = var.rds_db ? 1 : 0

  identifier        = lower("${local.name_prefix}-${var.deployment_id}")
  subnet_group_name = lower("${local.name_prefix}-${var.deployment_id}-rds_db_subnet")
  subnet_ids        = local.private_subnets

  engine         = var.rds_db_type
  engine_version = var.rds_db_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp2"

  db_name  = var.cloudbeaver-db-env[2].value
  username = var.cloudbeaver-db-env[1].value
  password = var.cloudbeaver-db-env[0].value

  vpc_security_group_ids = [aws_security_group.dbeaver_te_private.id]

  skip_final_snapshot = true

  tags = {
    Env  = var.deployment_id
    Name = "DBeaver Team Edition Database"
  }
}
