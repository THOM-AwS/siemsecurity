

# Application Load Balancer, Listener, and Target Group for Grafana
resource "aws_lb" "soc_alb" {
  name               = "soc-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.all.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "grafana_listener" {
  load_balancer_arn = aws_lb.soc_alb.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.apse2_cert_validation.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }
}

resource "aws_lb_target_group" "grafana_tg" {
  name        = "grafana-tg"
  port        = 3000
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

resource "aws_lb_target_group_attachment" "grafana_attachment" {
  target_group_arn = aws_lb_target_group.grafana_tg.arn
  target_id        = module.ec2_grafana.id
  port             = 3000
}

# Wazuh Dashboard Target Group
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
    matcher             = "200-299"
  }
}

# Wazuh Dashboard Target Group Attachment
resource "aws_lb_target_group_attachment" "wazuh_attachment" {
  target_group_arn = aws_lb_target_group.wazuh_tg.arn
  target_id        = module.ec2_wazuh-indexer-01.id
  port             = 443
}

# Listener for Wazuh Dashboard
resource "aws_lb_listener" "wazuh_listener" {
  load_balancer_arn = aws_lb.soc_alb.arn
  port              = "81"
  protocol          = "HTTP"

  # Assuming you want to route traffic to the Wazuh dashboard based on path
  # Update this rule as necessary based on your desired routing criteria
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wazuh_tg.arn
  }
}


