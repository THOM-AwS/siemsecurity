# Network Load Balancer
resource "aws_lb" "nlb_wazuh" {
  name               = "wazuh-nlb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.wazuh-nlb.id]
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

resource "aws_lb_target_group" "tg_22" {
  name     = "tg-22"
  port     = 22
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

resource "aws_lb_listener" "listener_22" {
  load_balancer_arn = aws_lb.nlb_wazuh.arn
  port              = 22
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_22.arn
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

resource "aws_lb_target_group_attachment" "attach_wazuh_22" {
  target_group_arn = aws_lb_target_group.tg_22.arn
  target_id        = module.ec2_wazuh.id
  port             = 22
}

resource "aws_security_group" "wazuh-nlb" {
  name        = "Wazuh-NLB"
  description = "Security group for Wazuh NLB"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1514
    to_port     = 1514
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1514
    to_port     = 1514
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1515
    to_port     = 1515
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 514
    to_port     = 514
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 55000
    to_port     = 55000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["220.233.103.214/32", "39.58.182.16/32", "206.84.143.26/32"]
  }

  ingress {
    from_port   = 514
    to_port     = 514
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9300
    to_port     = 9400
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1516
    to_port     = 1516
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Wazuh-NLB"
  }
}
