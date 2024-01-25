
# # Task definition for Grafana
# resource "aws_ecs_task_definition" "grafana" {
#   family                   = "grafana"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = "256" # Adjust as needed
#   memory                   = "512" # Adjust as needed
#   execution_role_arn       = aws_iam_role.ecs_execution_role.arn

#   container_definitions = jsonencode([
#     {
#       name  = "grafana",
#       image = "grafana/grafana-enterprise:latest",

#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
#           awslogs-region        = "us-east-1"
#           awslogs-stream-prefix = "grafana"
#         }
#       }

#       cpu       = 256,
#       memory    = 512,
#       essential = true,
#       portMappings = [
#         {
#           containerPort = 3000,
#           hostPort      = 3000,
#         },
#       ],

#       healthCheck = {
#         command     = ["CMD-SHELL", "curl -f http://localhost:3000/ || exit 1"]
#         interval    = 30
#         timeout     = 5
#         retries     = 3
#         startPeriod = 15
#       }
#     },
#   ])
# }

# # Task definition for Prometheus
# resource "aws_ecs_task_definition" "prometheus" {
#   family                   = "prometheus"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = "256" # Adjust as needed
#   memory                   = "512" # Adjust as needed
#   execution_role_arn       = aws_iam_role.ecs_execution_role.arn

#   container_definitions = jsonencode([
#     {
#       name  = "prometheus",
#       image = "prom/prometheus:latest",

#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
#           awslogs-region        = "us-east-1"
#           awslogs-stream-prefix = "prometheus"
#         }
#       }

#       cpu       = 256,
#       memory    = 512,
#       essential = true,
#       healthCheck = {
#         command     = ["CMD-SHELL", "curl -f http://localhost:9090/ || exit 1"]
#         interval    = 30
#         timeout     = 5
#         retries     = 3
#         startPeriod = 15
#       }
#       portMappings = [
#         {
#           containerPort = 9090,
#           hostPort      = 9090,
#         },
#       ],
#     },
#   ])
# }

# # ECS Cluster
# resource "aws_ecs_cluster" "fargate_cluster" {
#   name = "fargate-cluster"
# }

# # # Fargate service for Grafana
# resource "aws_ecs_service" "grafana_service" {
#   name            = "grafana-service"
#   cluster         = aws_ecs_cluster.fargate_cluster.id
#   task_definition = aws_ecs_task_definition.grafana.arn
#   launch_type     = "FARGATE"
#   desired_count   = 1

#   load_balancer {
#     target_group_arn = aws_lb_target_group.grafana_tg.arn
#     container_name   = "grafana"
#     container_port   = 3000
#   }

#   network_configuration {
#     subnets         = [aws_subnet.private1.id, aws_subnet.private2.id]
#     security_groups = [aws_security_group.fargate_sg.id]
#   }

#   depends_on = [
#     aws_lb.grafana_alb,
#     aws_lb_target_group.grafana_tg
#   ]
# }

# # Fargate service for Prometheus
# resource "aws_ecs_service" "prometheus_service" {
#   name            = "prometheus-service"
#   cluster         = aws_ecs_cluster.fargate_cluster.id
#   task_definition = aws_ecs_task_definition.prometheus.arn
#   launch_type     = "FARGATE"
#   desired_count   = 1

#   network_configuration {
#     subnets         = [aws_subnet.private1.id, aws_subnet.private2.id]
#     security_groups = [aws_security_group.fargate_sg.id]
#   }
# }
