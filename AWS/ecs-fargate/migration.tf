################################################################################
# VPC
################################################################################

moved {
  from = aws_vpc.dbeaver_net
  to   = module.vpc[0].aws_vpc.this
}

moved {
  from = aws_subnet.public_subnets[0]
  to   = module.vpc[0].aws_subnet.public[0]
}

moved {
  from = aws_subnet.public_subnets[1]
  to   = module.vpc[0].aws_subnet.public[1]
}

moved {
  from = aws_subnet.private_subnets[0]
  to   = module.vpc[0].aws_subnet.private[0]
}

moved {
  from = aws_subnet.private_subnets[1]
  to   = module.vpc[0].aws_subnet.private[1]
}

moved {
  from = aws_internet_gateway.dbeaver_gw
  to   = module.vpc[0].aws_internet_gateway.this
}

moved {
  from = aws_eip.dbeaver_nat_gateway
  to   = module.vpc[0].aws_eip.nat
}

moved {
  from = aws_nat_gateway.nat_gateway
  to   = module.vpc[0].aws_nat_gateway.this
}

removed {
  from = aws_route.dbeaver_vpc_main_gw
  lifecycle { destroy = true }
}

removed {
  from = aws_route_table.dbeaver_private_rt_nat
  lifecycle { destroy = true }
}

removed {
  from = aws_route_table_association.private_subnets_rt
  lifecycle { destroy = true }
}


################################################################################
# IAM
################################################################################

moved {
  from = aws_iam_role.ecsTaskExecutionRole
  to   = module.iam.aws_iam_role.execution
}

moved {
  from = aws_iam_role.ecs_task_role_exec
  to   = module.iam.aws_iam_role.task
}

moved {
  from = aws_iam_policy.CloudbeaverTeamEditionEFSAccessPolicy
  to   = module.iam.aws_iam_policy.efs_access
}

moved {
  from = aws_iam_role_policy_attachment.ecsTaskExecutionRole_policy
  to   = module.iam.aws_iam_role_policy_attachment.execution_ecs
}

moved {
  from = aws_iam_role_policy_attachment.TeamEditionEFSAccessPolicy_attachment
  to   = module.iam.aws_iam_role_policy_attachment.execution_efs
}

moved {
  from = aws_iam_role_policy_attachment.ecs_task_role_exec_ssm
  to   = module.iam.aws_iam_role_policy_attachment.task_ssm
}

removed {
  from = aws_iam_role_policy_attachment.logs_policy_attachment
  lifecycle { destroy = true }
}

removed {
  from = aws_iam_role_policy_attachment.ecs_task_role_exec_logs
  lifecycle { destroy = true }
}


################################################################################
# RDS
################################################################################

moved {
  from = aws_db_subnet_group.rds_dbeaver_db_subnet[0]
  to   = module.rds[0].aws_db_subnet_group.this
}

moved {
  from = aws_db_instance.rds_dbeaver_db[0]
  to   = module.rds[0].aws_db_instance.this
}


################################################################################
# EFS
################################################################################

moved {
  from = aws_efs_file_system.cloudbeaver_db_data
  to   = module.efs["db_data"].aws_efs_file_system.this
}

moved {
  from = aws_efs_mount_target.cloudbeaver_db_data_mt[0]
  to   = module.efs["db_data"].aws_efs_mount_target.this[0]
}

moved {
  from = aws_efs_mount_target.cloudbeaver_db_data_mt[1]
  to   = module.efs["db_data"].aws_efs_mount_target.this[1]
}

moved {
  from = aws_efs_file_system.cloudbeaver_dc_data
  to   = module.efs["dc_data"].aws_efs_file_system.this
}

moved {
  from = aws_efs_mount_target.cloudbeaver_dc_data_mt[0]
  to   = module.efs["dc_data"].aws_efs_mount_target.this[0]
}

moved {
  from = aws_efs_mount_target.cloudbeaver_dc_data_mt[1]
  to   = module.efs["dc_data"].aws_efs_mount_target.this[1]
}

moved {
  from = aws_efs_file_system.cloudbeaver_rm_data
  to   = module.efs["rm_data"].aws_efs_file_system.this
}

moved {
  from = aws_efs_mount_target.cloudbeaver_rm_data_mt[0]
  to   = module.efs["rm_data"].aws_efs_mount_target.this[0]
}

moved {
  from = aws_efs_mount_target.cloudbeaver_rm_data_mt[1]
  to   = module.efs["rm_data"].aws_efs_mount_target.this[1]
}

moved {
  from = aws_efs_file_system.cloudbeaver_tm_data
  to   = module.efs["tm_data"].aws_efs_file_system.this
}

moved {
  from = aws_efs_mount_target.cloudbeaver_tm_data_mt[0]
  to   = module.efs["tm_data"].aws_efs_mount_target.this[0]
}

moved {
  from = aws_efs_mount_target.cloudbeaver_tm_data_mt[1]
  to   = module.efs["tm_data"].aws_efs_mount_target.this[1]
}

moved {
  from = aws_efs_file_system.cloudbeaver_certificates
  to   = module.efs["certificates"].aws_efs_file_system.this
}

moved {
  from = aws_efs_access_point.certs_public
  to   = module.efs["certificates"].aws_efs_access_point.this[0]
}

moved {
  from = aws_efs_mount_target.cloudbeaver_certificates_mt[0]
  to   = module.efs["certificates"].aws_efs_mount_target.this[0]
}

moved {
  from = aws_efs_mount_target.cloudbeaver_certificates_mt[1]
  to   = module.efs["certificates"].aws_efs_mount_target.this[1]
}

moved {
  from = aws_efs_file_system.api_tokens
  to   = module.efs["api_tokens"].aws_efs_file_system.this
}

moved {
  from = aws_efs_mount_target.api_tokens_mt[0]
  to   = module.efs["api_tokens"].aws_efs_mount_target.this[0]
}

moved {
  from = aws_efs_mount_target.api_tokens_mt[1]
  to   = module.efs["api_tokens"].aws_efs_mount_target.this[1]
}


################################################################################
# ECS
################################################################################

moved {
  from = aws_ecs_cluster.dbeaver_te
  to   = module.ecs_cluster.aws_ecs_cluster.this
}

moved {
  from = aws_ecs_task_definition.dbeaver_te
  to   = module.cloudbeaver_te.aws_ecs_task_definition.this
}

moved {
  from = aws_ecs_task_definition.dbeaver_dc
  to   = module.cloudbeaver_dc.aws_ecs_task_definition.this
}

moved {
  from = aws_ecs_task_definition.dbeaver_qm
  to   = module.cloudbeaver_qm.aws_ecs_task_definition.this
}

moved {
  from = aws_ecs_task_definition.dbeaver_rm
  to   = module.cloudbeaver_rm.aws_ecs_task_definition.this
}

moved {
  from = aws_ecs_task_definition.dbeaver_tm
  to   = module.cloudbeaver_tm.aws_ecs_task_definition.this
}

moved {
  from = aws_ecs_task_definition.kafka
  to   = module.kafka.aws_ecs_task_definition.this
}

moved {
  from = aws_ecs_task_definition.dbeaver_db[0]
  to   = module.postgres[0].aws_ecs_task_definition.this
}

moved {
  from = aws_ecs_service.te
  to   = module.cloudbeaver_te.aws_ecs_service.this
}

moved {
  from = aws_ecs_service.dc
  to   = module.cloudbeaver_dc.aws_ecs_service.this
}

moved {
  from = aws_ecs_service.qm
  to   = module.cloudbeaver_qm.aws_ecs_service.this
}

moved {
  from = aws_ecs_service.rm
  to   = module.cloudbeaver_rm.aws_ecs_service.this
}

moved {
  from = aws_ecs_service.tm
  to   = module.cloudbeaver_tm.aws_ecs_service.this
}

moved {
  from = aws_ecs_service.kafka
  to   = module.kafka.aws_ecs_service.this
}

moved {
  from = aws_ecs_service.postgres[0]
  to   = module.postgres[0].aws_ecs_service.this
}


################################################################################
# ALB
################################################################################

moved {
  from = aws_lb.dbeaver_te_lb
  to   = module.alb.aws_lb.this
}

moved {
  from = aws_lb_listener.dbeaver-te-listener
  to   = module.alb.aws_lb_listener.http
}

moved {
  from = aws_lb_listener.dbeaver-te-listener-https
  to   = module.alb.aws_lb_listener.https
}

moved {
  from = aws_lb_target_group.dbeaver_te
  to   = module.cloudbeaver_te_route.aws_lb_target_group.this
}

moved {
  from = aws_lb_target_group.dbeaver_dc
  to   = module.cloudbeaver_dc_route.aws_lb_target_group.this
}

moved {
  from = aws_lb_target_group.dbeaver_qm
  to   = module.cloudbeaver_qm_route.aws_lb_target_group.this
}

moved {
  from = aws_lb_target_group.dbeaver_rm
  to   = module.cloudbeaver_rm_route.aws_lb_target_group.this
}

moved {
  from = aws_lb_target_group.dbeaver_tm
  to   = module.cloudbeaver_tm_route.aws_lb_target_group.this
}

moved {
  from = aws_lb_listener_rule.forward_to_service_uri_dc
  to   = module.cloudbeaver_dc_route.aws_lb_listener_rule.this
}

moved {
  from = aws_lb_listener_rule.forward_to_service_uri_qm
  to   = module.cloudbeaver_qm_route.aws_lb_listener_rule.this
}

moved {
  from = aws_lb_listener_rule.forward_to_service_uri_rm
  to   = module.cloudbeaver_rm_route.aws_lb_listener_rule.this
}

moved {
  from = aws_lb_listener_rule.forward_to_service_uri_tm
  to   = module.cloudbeaver_tm_route.aws_lb_listener_rule.this
}
