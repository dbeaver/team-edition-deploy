resource "aws_efs_file_system" "this" {
  creation_token   = "${var.deployment_id}-${var.name}"
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode
  encrypted        = var.encrypted

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${var.deployment_id}-${var.name}"
  })
}

resource "aws_efs_mount_target" "this" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = var.security_group_ids
}

resource "aws_efs_access_point" "this" {
  count          = var.access_point != null ? 1 : 0
  file_system_id = aws_efs_file_system.this.id

  root_directory {
    path = var.access_point.path

    creation_info {
      owner_uid   = var.access_point.owner_uid
      owner_gid   = var.access_point.owner_gid
      permissions = var.access_point.permissions
    }
  }

  posix_user {
    uid = var.access_point.owner_uid
    gid = var.access_point.owner_gid
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${var.deployment_id}-${var.name}"
  })
}
