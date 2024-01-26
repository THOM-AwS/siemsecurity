resource "aws_iam_role" "ec2_instance_role" {
  name = "ec2-instance-role-generic"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ],
  })
}

# role attachments
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}







# # Execution role for Fargate
# resource "aws_iam_role" "ecs_execution_role" {
#   name = "ecs_execution_role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         },
#       },
#     ],
#   })
# }

# resource "aws_iam_role_policy" "ecs_execution_role_policy" {
#   name = "ecs_execution_role_policy"
#   role = aws_iam_role.ecs_execution_role.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = [
#           "logs:CreateLogStream",
#           "logs:CreateLogGroup",
#           "logs:PutLogEvents"
#         ],
#         Effect   = "Allow",
#         Resource = "arn:aws:logs:us-east-1:941133421128:log-group:/ecs/siem:*"
#       },
#     ]
#   })
# }
