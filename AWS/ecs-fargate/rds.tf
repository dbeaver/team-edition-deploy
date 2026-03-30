################################################################################
# RDS PostgreSQL (optional, enabled via var.rds_db)
################################################################################

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  count = var.rds_db ? 1 : 0

  identifier = "dbeaverte-${var.deployment_id}"

  engine         = var.rds_db_type
  engine_version = var.rds_db_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp2"

  db_name  = var.cloudbeaver-db-env[2].value
  username = var.cloudbeaver-db-env[1].value

  manage_master_user_password = false
  password                    = var.cloudbeaver-db-env[0].value

  create_db_subnet_group = true
  db_subnet_group_name   = "dbeaverte-${var.deployment_id}-rds_db_subnet"
  subnet_ids             = module.vpc.private_subnets

  vpc_security_group_ids = [aws_security_group.dbeaver_te_private.id]

  skip_final_snapshot = true

  create_monitoring_role    = false
  create_db_option_group    = false
  create_db_parameter_group = false

  tags = {
    Env  = var.deployment_id
    Name = "DBeaver Team Edition Database"
  }
}
