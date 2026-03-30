################################################################################
# Migration of old resources to new modules
################################################################################

moved {
  from = aws_vpc.dbeaver_net
  to   = module.vpc.aws_vpc.this[0]
}

moved {
  from = aws_subnet.public_subnets[0]
  to   = module.vpc.aws_subnet.public[0]
}

moved {
  from = aws_subnet.public_subnets[1]
  to   = module.vpc.aws_subnet.public[1]
}

moved {
  from = aws_subnet.private_subnets[0]
  to   = module.vpc.aws_subnet.private[0]
}

moved {
  from = aws_subnet.private_subnets[1]
  to   = module.vpc.aws_subnet.private[1]
}

moved {
  from = aws_internet_gateway.dbeaver_gw
  to   = module.vpc.aws_internet_gateway.this[0]
}

moved {
  from = aws_eip.dbeaver_nat_gateway
  to   = module.vpc.aws_eip.nat[0]
}

moved {
  from = aws_nat_gateway.nat_gateway
  to   = module.vpc.aws_nat_gateway.this[0]
}

moved {
  from = aws_route_table.dbeaver_private_rt_nat
  to   = module.vpc.aws_route_table.private[0]
}

moved {
  from = aws_route_table_association.private_subnets_rt[0]
  to   = module.vpc.aws_route_table_association.private[0]
}

moved {
  from = aws_route_table_association.private_subnets_rt[1]
  to   = module.vpc.aws_route_table_association.private[1]
}

moved {
  from = aws_ecs_cluster.dbeaver_te
  to   = module.ecs_cluster.aws_ecs_cluster.this[0]
}

moved {
  from = aws_db_subnet_group.rds_dbeaver_db_subnet[0]
  to   = module.rds[0].module.db_subnet_group.aws_db_subnet_group.this[0]
}

moved {
  from = aws_db_instance.rds_dbeaver_db[0]
  to   = module.rds[0].module.db_instance.aws_db_instance.this[0]
}
