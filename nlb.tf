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

resource "aws_lb_target_group" "tg_55000" {
  name     = "tg-55000"
  port     = 55000
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group" "tg_9200" {
  name     = "tg-9200"
  port     = 9200
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id
}

# TLS Listeners with ACM Certificate
resource "aws_lb_listener" "listener_1514" {
  load_balancer_arn = aws_lb.nlb_wazuh.arn
  port              = 1514
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_1514.arn
  }
}

resource "aws_lb_listener" "listener_1515" {
  load_balancer_arn = aws_lb.nlb_wazuh.arn
  port              = 1515
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_1515.arn
  }
}

resource "aws_lb_listener" "listener_55000" {
  load_balancer_arn = aws_lb.nlb_wazuh.arn
  port              = 55000
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_55000.arn
  }
}

resource "aws_lb_listener" "listener_9200" {
  load_balancer_arn = aws_lb.nlb_wazuh.arn
  port              = 9200
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_9200.arn
  }
}

# Attach the Wazuh indexer instance to the target group for port 1514
resource "aws_lb_target_group_attachment" "attach_wazuh_1514" {
  target_group_arn = aws_lb_target_group.tg_1514.arn
  target_id        = module.ec2_wazuh.id
  port             = 1514
}

# Attach the Wazuh indexer instance to the target group for port 1515
resource "aws_lb_target_group_attachment" "attach_wazuh_1515" {
  target_group_arn = aws_lb_target_group.tg_1515.arn
  target_id        = module.ec2_wazuh.id
  port             = 1515
}

# Attach the Wazuh indexer instance to the target group for port 1515
resource "aws_lb_target_group_attachment" "attach_wazuh_55000" {
  target_group_arn = aws_lb_target_group.tg_55000.arn
  target_id        = module.ec2_wazuh.id
  port             = 55000
}

resource "aws_lb_target_group_attachment" "attach_wazuh_9200" {
  target_group_arn = aws_lb_target_group.tg_9200.arn
  target_id        = module.ec2_wazuh.id
  port             = 9200
}
