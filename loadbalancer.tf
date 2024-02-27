

# Application Load Balancer, Listener, and Target Group for Grafana
resource "aws_lb" "soc_alb" {
  name               = "soc-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.all.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.soc_alb.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation._127cyber_wildcard_cert_validation.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 Not Found"
      status_code  = "404"
    }
  }
}

## Listener rules

resource "aws_lb_listener_rule" "wazuh_subdomain" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wazuh_tg.arn
  }

  condition {
    host_header {
      values = ["wazuh.127cyber.com"]
    }
  }
}

# resource "aws_lb_listener_rule" "graylog_subdomain" {
#   listener_arn = aws_lb_listener.https_listener.arn
#   priority     = 103

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.graylog_tg.arn
#   }

#   condition {
#     host_header {
#       values = ["graylog.127cyber.com"]
#     }
#   }
# }

# resource "aws_lb_listener_rule" "grafana_subdomain" {
#   listener_arn = aws_lb_listener.https_listener.arn
#   priority     = 105

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.grafana_tg.arn
#   }

#   condition {
#     host_header {
#       values = ["grafana.127cyber.com"]
#     }
#   }
# }

## Target groups
# resource "aws_lb_target_group" "grafana_tg" {
#   name        = "grafana-tg"
#   port        = 3000
#   protocol    = "HTTP"
#   vpc_id      = aws_vpc.main.id
#   target_type = "instance"

#   health_check {
#     enabled             = true
#     interval            = 30
#     path                = "/"
#     port                = "traffic-port"
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     timeout             = 5
#     matcher             = "200-399"
#   }
# }

resource "aws_lb_target_group" "wazuh_tg" {
  name        = "wazuh-tg"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200-399"
  }
}

# resource "aws_lb_target_group" "graylog_tg" {
#   name        = "graylog-tg"
#   port        = 9000
#   protocol    = "HTTPS"
#   vpc_id      = aws_vpc.main.id
#   target_type = "instance"

#   health_check {
#     enabled             = true
#     interval            = 30
#     path                = "/"
#     port                = "traffic-port"
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     timeout             = 5
#     matcher             = "200-399"
#   }
# }

# ## Target group attachments
# resource "aws_lb_target_group_attachment" "grafana_attachment" {
#   target_group_arn = aws_lb_target_group.grafana_tg.arn
#   target_id        = module.ec2_grafana.id
#   port             = 3000
# }

resource "aws_lb_target_group_attachment" "wazuh_attachment" {
  target_group_arn = aws_lb_target_group.wazuh_tg.arn
  target_id        = module.ec2_wazuh.id
  port             = 443
}

# resource "aws_lb_target_group_attachment" "graylog_attachment" {
#   target_group_arn = aws_lb_target_group.graylog_tg.arn
#   target_id        = module.ec2_graylog.id
#   port             = 9000
# }


