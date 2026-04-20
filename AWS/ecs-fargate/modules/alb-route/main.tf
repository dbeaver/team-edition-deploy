resource "aws_lb_target_group" "this" {
  name        = var.name
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    matcher             = var.health_check_matcher
    unhealthy_threshold = var.health_check_unhealthy_threshold
    enabled             = true
    path                = var.health_check_path
  }

  dynamic "stickiness" {
    for_each = var.stickiness_enabled ? [1] : []
    content {
      enabled         = true
      type            = "lb_cookie"
      cookie_duration = var.stickiness_duration
    }
  }

  tags = var.tags
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = var.listener_arn
  priority     = var.priority

  condition {
    path_pattern {
      values = [var.path_pattern]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = var.tags
}
