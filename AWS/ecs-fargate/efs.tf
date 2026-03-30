################################################################################
# DB Data
################################################################################

resource "aws_efs_file_system" "cloudbeaver_db_data" {
  creation_token   = "${var.deployment_id}-cloudbeaver_db_data"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags = {
    Env  = var.deployment_id
    Name = "DBeaver TE DATA EFS"
  }
}

resource "aws_efs_mount_target" "cloudbeaver_db_data_mt" {
  count           = length(local.private_subnets)
  file_system_id  = aws_efs_file_system.cloudbeaver_db_data.id
  subnet_id       = local.private_subnets[count.index]
  security_groups = [aws_security_group.dbeaver_efs.id]
}

################################################################################
# RM Data
################################################################################

resource "aws_efs_file_system" "cloudbeaver_rm_data" {
  creation_token   = "${var.deployment_id}-cloudbeaver_rm_data"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags = {
    Env  = var.deployment_id
    Name = "DBeaver TE RM DATA EFS"
  }
}

resource "aws_efs_mount_target" "cloudbeaver_rm_data_mt" {
  count           = length(local.private_subnets)
  file_system_id  = aws_efs_file_system.cloudbeaver_rm_data.id
  subnet_id       = local.private_subnets[count.index]
  security_groups = [aws_security_group.dbeaver_efs.id]
}

################################################################################
# TM Data
################################################################################

resource "aws_efs_file_system" "cloudbeaver_tm_data" {
  creation_token   = "${var.deployment_id}-cloudbeaver_tm_data"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags = {
    Env  = var.deployment_id
    Name = "DBeaver TE TM DATA EFS"
  }
}

resource "aws_efs_mount_target" "cloudbeaver_tm_data_mt" {
  count           = length(local.private_subnets)
  file_system_id  = aws_efs_file_system.cloudbeaver_tm_data.id
  subnet_id       = local.private_subnets[count.index]
  security_groups = [aws_security_group.dbeaver_efs.id]
}

################################################################################
# DC Data
################################################################################

resource "aws_efs_file_system" "cloudbeaver_dc_data" {
  creation_token   = "${var.deployment_id}-cloudbeaver_dc_data"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags = {
    Env  = var.deployment_id
    Name = "DBeaver TE DC DATA EFS"
  }
}

resource "aws_efs_mount_target" "cloudbeaver_dc_data_mt" {
  count           = length(local.private_subnets)
  file_system_id  = aws_efs_file_system.cloudbeaver_dc_data.id
  subnet_id       = local.private_subnets[count.index]
  security_groups = [aws_security_group.dbeaver_efs.id]
}

################################################################################
# Certificates
################################################################################

resource "aws_efs_file_system" "cloudbeaver_certificates" {
  creation_token   = "${var.deployment_id}-cloudbeaver_certificates"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags = {
    Env  = var.deployment_id
    Name = "DBeaver TE CERTIFICATES EFS"
  }
}

resource "aws_efs_access_point" "certs_public" {
  file_system_id = aws_efs_file_system.cloudbeaver_certificates.id
  root_directory {
    path = "/public"

    creation_info {
      owner_uid   = 8978
      owner_gid   = 8978
      permissions = "0755"
    }
  }

  posix_user {
    uid = 8978
    gid = 8978
  }

  tags = {
    Env  = var.deployment_id
    Name = "DBeaver TE PUBLIC CERTIFICATES MOUNTPOINT EFS"
  }
}

resource "aws_efs_mount_target" "cloudbeaver_certificates_mt" {
  count           = length(local.private_subnets)
  file_system_id  = aws_efs_file_system.cloudbeaver_certificates.id
  subnet_id       = local.private_subnets[count.index]
  security_groups = [aws_security_group.dbeaver_efs.id]
}

################################################################################
# API Tokens
################################################################################

resource "aws_efs_file_system" "api_tokens" {
  creation_token   = "${var.deployment_id}-api_tokens"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags = {
    Env  = var.deployment_id
    Name = "DBeaver TE API TOKENS EFS"
  }
}

resource "aws_efs_mount_target" "api_tokens_mt" {
  count           = length(local.private_subnets)
  file_system_id  = aws_efs_file_system.api_tokens.id
  subnet_id       = local.private_subnets[count.index]
  security_groups = [aws_security_group.dbeaver_efs.id]
}
