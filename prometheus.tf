
# module "ec2_prometheus" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "3.0.0"

#   name = "Prometheus"

#   ami                    = "ami-09ccb67fcbf1d625c"
#   instance_type          = "t3.small"
#   subnet_id              = aws_subnet.private2.id
#   vpc_security_group_ids = [aws_security_group.all.id]
#   iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

#   tags = {
#     Terraform   = "true"
#     Environment = "prod"
#   }
# }

# # Persistent EBS Volume
# resource "aws_ebs_volume" "gp3_volume_prometheus" {
#   availability_zone = "ap-southeast-2b"
#   size              = 100
#   type              = "gp3"

#   tags = {
#     Name = "prometheus_persistence"
#   }
# }

# # Attach the first volume to the first instance
# resource "aws_volume_attachment" "ebs_att_prometheus" {
#   device_name  = "/dev/sdh"
#   volume_id    = aws_ebs_volume.gp3_volume_prometheus.id
#   instance_id  = module.ec2_prometheus.id
#   force_detach = true
# }
