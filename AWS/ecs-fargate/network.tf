resource "aws_vpc" "dbeaver_net" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Env  = var.environment
    Name = "DBeaverTeamEdition"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnets" {
  count      = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.dbeaver_net.id
  cidr_block = element(var.public_subnet_cidrs, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Env  = var.environment
    Name = "DBeaverTE Public Subnet ${count.index + 1}"
  }

  depends_on = [aws_vpc.dbeaver_net]
}

resource "aws_subnet" "private_subnets" {
  count      = length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.dbeaver_net.id
  cidr_block = element(var.private_subnet_cidrs, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Env  = var.environment
    Name = "DBeaverTE Private Subnet ${count.index + 1}"
  }

  depends_on = [aws_vpc.dbeaver_net]
}

resource "aws_internet_gateway" "dbeaver_gw" {
  vpc_id = aws_vpc.dbeaver_net.id

  tags = {
    Env  = var.environment
    Name = "DBeaverTE VPC IG"
  }
  depends_on = [aws_vpc.dbeaver_net]
}


resource "aws_route" "dbeaver_vpc_main_gw" {
  route_table_id = aws_vpc.dbeaver_net.main_route_table_id

  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.dbeaver_gw.id
  depends_on = [
    aws_vpc.dbeaver_net,
    aws_internet_gateway.dbeaver_gw
  ]
}


resource "aws_eip" "dbeaver_nat_gateway" {
  domain           = "vpc"
  tags = {
    Env  = var.environment
    Name = "DBeaverTE EIP for Private VPC "
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.dbeaver_nat_gateway.id
  subnet_id = aws_subnet.public_subnets[0].id
  tags = {
    Env  = var.environment
    Name = "DBeaverTE Private Subnets Nat Gateway"
  }

  depends_on = [
    aws_vpc.dbeaver_net,
    aws_subnet.public_subnets
  ]
}

resource "aws_route_table" "dbeaver_private_rt_nat" {
  vpc_id = aws_vpc.dbeaver_net.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Env  = var.environment
    Name = "DBeaver TE Private Route Table"
  }
  depends_on = [
    aws_vpc.dbeaver_net,
    aws_eip.dbeaver_nat_gateway
  ]
}

resource "aws_route_table_association" "private_subnets_rt" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.dbeaver_private_rt_nat.id
}