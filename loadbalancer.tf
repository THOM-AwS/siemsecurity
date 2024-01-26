

# Application Load Balancer, Listener, and Target Group for Grafana
resource "aws_lb" "grafana_alb" {
  name               = "grafana-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.all.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "grafana_listener" {
  load_balancer_arn = aws_lb.grafana_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }
}

resource "aws_lb_target_group" "grafana_tg" {
  name        = "grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

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

resource "aws_lb_target_group_attachment" "grafana_attachment" {
  target_group_arn = aws_lb_target_group.grafana_tg.arn
  target_id        = module.ec2_grafana.id
  port             = 3000
}
