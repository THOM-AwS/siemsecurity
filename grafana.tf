

# module "ec2_grafana" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "3.0.0"

#   name = "Grafana"

#   ami                    = "ami-09ccb67fcbf1d625c"
#   instance_type          = "t3.small"
#   subnet_id              = aws_subnet.private1.id
#   vpc_security_group_ids = [aws_security_group.all.id]
#   iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

#   tags = {
#     Terraform   = "true"
#     Environment = "prod"
#   }
# }

# # Persistent EBS Volume
# resource "aws_ebs_volume" "gp3_volume_grafana" {
#   availability_zone = "ap-southeast-2a"
#   size              = 10
#   type              = "gp3"
# }

# # Attach the first volume to the first instance
# resource "aws_volume_attachment" "ebs_att_grafana" {
#   device_name  = "/dev/sdh"
#   volume_id    = aws_ebs_volume.gp3_volume_grafana.id
#   instance_id  = module.ec2_grafana.id
#   force_detach = true
# }
