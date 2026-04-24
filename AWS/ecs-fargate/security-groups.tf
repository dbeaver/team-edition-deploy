################################################################################
# Security Groups
################################################################################

resource "aws_security_group" "dbeaver_alb" {
  name        = "${local.name_prefix}-${var.deployment_id}-sg-alb"
  vpc_id      = local.vpc_id
  description = "DBeaverTE ${var.deployment_id} EKS Default SG"

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "HTTP"
  }

  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "HTTPS"
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Env = var.deployment_id
  }
}

resource "aws_security_group" "dbeaver_efs" {
  name        = "${local.name_prefix}-${var.deployment_id}-ecs-efs-sg"
  vpc_id      = local.vpc_id
  description = "DBeaverTE ${var.deployment_id} efs SG"

  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = var.private_subnet_cidrs
    description = "Allow NFS traffic - TCP 2049"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Env = var.deployment_id
  }
}

resource "aws_security_group" "dbeaver_te_private" {
  name        = "${local.name_prefix}-${var.deployment_id}-ecs-service-postgres"
  vpc_id      = local.vpc_id
  description = "DBeaverTE ${var.deployment_id} ECS Postgres SG"

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = var.private_subnet_cidrs
    description = "PostgreSQL"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 9092
    to_port     = 9093
    cidr_blocks = var.private_subnet_cidrs
    description = "Kafka"
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Env = var.deployment_id
  }
}

resource "aws_security_group" "dbeaver_te" {
  name        = "${local.name_prefix}-${var.deployment_id}-ecs-service-dbeaver-te"
  vpc_id      = local.vpc_id
  description = "DBeaverTE ${var.deployment_id} ECS DBeaverTE SG"

  ingress {
    protocol    = "tcp"
    from_port   = 8970
    to_port     = 8980
    cidr_blocks = concat(var.private_subnet_cidrs, var.public_subnet_cidrs)
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Env = var.deployment_id
  }
}
