
################################################################################
# ALB
################################################################################

resource "aws_lb" "dbeaver_te_lb" {
  name               = "DBeaverTE-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.dbeaver_alb.id]
  subnets            = aws_subnet.public_subnets[*].id
  tags = {
    env = "dev"
  }
}


# This resources must be edited if HTTPS not used
resource "aws_lb_listener" "dbeaver-te-listener" {

  load_balancer_arn = aws_lb.dbeaver_te_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
# This resources must be edited if HTTPS not used
resource "aws_lb_listener" "dbeaver-te-listener-https" {

  load_balancer_arn = aws_lb.dbeaver_te_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = "arn:aws:acm:${var.dbeaver-aws-region}:${var.aws_account_id}:certificate/${var.alb_certificate_Identifier}"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dbeaver_te.arn
  }
}

resource "aws_lb_listener_rule" "forward_to_service_uri_dc" {
  listener_arn = aws_lb_listener.dbeaver-te-listener-https.arn
  priority     = 99

  condition {
    path_pattern {
      values = ["/dc*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dbeaver_dc.arn
  }
}

resource "aws_lb_listener_rule" "forward_to_service_uri_qm" {
  listener_arn = aws_lb_listener.dbeaver-te-listener-https.arn
  priority     = 98

  condition {
    path_pattern {
      values = ["/qm*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dbeaver_qm.arn
  }
}

resource "aws_lb_listener_rule" "forward_to_service_uri_rm" {
  listener_arn = aws_lb_listener.dbeaver-te-listener-https.arn
  priority     = 97

  condition {
    path_pattern {
      values = ["/rm*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dbeaver_rm.arn
  }
}


resource "aws_lb_listener_rule" "forward_to_service_uri_tm" {
  listener_arn = aws_lb_listener.dbeaver-te-listener-https.arn
  priority     = 94

  condition {
    path_pattern {
      values = ["/tm*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dbeaver_tm.arn
  }
}


resource "aws_lb_target_group" "dbeaver_dc" {
  name        = "DBeaverTE-dc"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.dbeaver_net.id

  health_check {
    matcher = "200,302"
    unhealthy_threshold = 7
    enabled = true
    path    = "/dc/health"
  }
}

resource "aws_lb_target_group" "dbeaver_te" {
  name        = "DBeaverTE"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.dbeaver_net.id

  health_check {
    matcher = "200,302"
    unhealthy_threshold = 10
    enabled = true
    path    = "/"
  }
}

resource "aws_lb_target_group" "dbeaver_qm" {
  name        = "DBeaverTE-qm"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.dbeaver_net.id

  health_check {
    matcher = "200,302"
    unhealthy_threshold = 7
    enabled = true
    path    = "/qm/health"
  }
}

resource "aws_lb_target_group" "dbeaver_rm" {
  name        = "DBeaverTE-rm"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.dbeaver_net.id

  health_check {
    matcher = "200,302"
    unhealthy_threshold = 7
    enabled = true
    path    = "/rm/health"
  }
}

resource "aws_lb_target_group" "dbeaver_tm" {
  name        = "DBeaverTE-tm"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.dbeaver_net.id

  health_check {
    matcher = "200,302"
    unhealthy_threshold = 7
    enabled = true
    path    = "/tm/health"
  }
}





