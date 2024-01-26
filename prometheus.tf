
module "ec2_prometheus" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "3.0.0"

  name = "Prometheus"

  ami                    = "ami-0a3c3a20c09d6f377"
  instance_type          = "t2.small"
  subnet_id              = aws_subnet.private2.id
  vpc_security_group_ids = [aws_security_group.all.id]

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}

# Persistent EBS Volume
resource "aws_ebs_volume" "gp3_volume_prometheus" {
  availability_zone = "us-east-1b"
  size              = 100
  type              = "gp3"

  tags = {
    Name = "prometheus_persistence"
  }
}

# Attach the first volume to the first instance
resource "aws_volume_attachment" "ebs_att_prometheus" {
  device_name  = "/dev/sdh"
  volume_id    = aws_ebs_volume.gp3_volume_prometheus.id
  instance_id  = module.ec2_prometheus.id
  force_detach = true
}
