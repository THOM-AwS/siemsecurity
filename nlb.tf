# Network Load Balancer
resource "aws_lb" "nlb_wazuh" {
  name               = "wazuh-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  enable_deletion_protection = false
}

# Target Groups for ports 1514 and 1515
resource "aws_lb_target_group" "tg_1514" {
  name     = "tg-1514"
  port     = 1514
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group" "tg_1515" {
  name     = "tg-1515"
  port     = 1515
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id
}

# TLS Listeners with ACM Certificate
resource "aws_lb_listener" "listener_1514" {
  load_balancer_arn = aws_lb.nlb_wazuh.arn
  port              = 1514
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.apse2_wildcard_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_1514.arn
  }
}

resource "aws_lb_listener" "listener_1515" {
  load_balancer_arn = aws_lb.nlb_wazuh.arn
  port              = 1515
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.apse2_wildcard_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_1515.arn
  }
}


