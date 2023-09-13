resource "aws_security_group" "dbeaver_alb" {
  name   = "DBeaverTE-sg-alb"
  vpc_id = aws_vpc.dbeaver_net.id
  description = "DBeaverTE EKS Default SG"

  ingress {
   protocol         = "tcp"
   from_port        = 80
   to_port          = 80
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
   protocol         = "tcp"
   from_port        = 443
   to_port          = 443
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }

  egress {
   protocol         = "-1"
   from_port        = 0
   to_port          = 0
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "dbeaver_efs" {
  name   = "ecs-DBeaverTE-efs-sg"
  vpc_id = aws_vpc.dbeaver_net.id
  description = "DBeaverTE efs SG"

  ingress {
   protocol         = "tcp"
   from_port        = 2049
   to_port          = 2049
   cidr_blocks = var.private_subnet_cidrs
   description = "Allow NFS traffic - TCP 2049"
  }

  egress {
   protocol         = "-1"
   from_port        = 0
   to_port          = 0
   cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "dbeaver_te_private" {
  name   = "ecs-DBeaverTE-service-postgres"
  vpc_id = aws_vpc.dbeaver_net.id
  description = "DBeaverTE ECS Postgres SG"

  ingress {
    protocol         = "tcp"
    from_port        = 5432
    to_port          = 5432
    cidr_blocks = var.private_subnet_cidrs
  }

   ingress {
    protocol         = "tcp"
    from_port        = 9092
    to_port          = 9093
    cidr_blocks = var.private_subnet_cidrs
  }

  egress {
   protocol         = "-1"
   from_port        = 0
   to_port          = 0
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }
}


resource "aws_security_group" "dbeaver_te" {
  name   = "ecs-DBeaverTE-service-dbeaver-te"
  vpc_id = aws_vpc.dbeaver_net.id
  description = "DBeaverTE ECS DBeaverTE SG"

  ingress {
   protocol         = "tcp"
   from_port        = 8970
   to_port          = 8980
   cidr_blocks = concat(var.private_subnet_cidrs, var.public_subnet_cidrs)
  }

  egress {
   protocol         = "-1"
   from_port        = 0
   to_port          = 0
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }
}