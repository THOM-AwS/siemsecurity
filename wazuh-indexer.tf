
module "ec2_wazuh-indexer-01" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "3.0.0"

  name = "wazuh-indexer-01"

  ami                    = "ami-0a3c3a20c09d6f377"
  instance_type          = "m5.xlarge"
  subnet_id              = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.all.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  root_block_device = [
    {
      # encrypted   = true
      volume_type = "gp3"
      # throughput  = 200
      volume_size = 50
      # tags = {
      #   Name = "my-root-block"
      # }
    },
  ]

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}

# Persistent EBS Volume
resource "aws_ebs_volume" "gp3_volume_wazuh-indexer" {
  availability_zone = "us-east-1a"
  size              = 100
  type              = "gp3"
}

# Attach the first volume to the first instance
resource "aws_volume_attachment" "ebs_att_wazuh-indexer-01" {
  device_name  = "/dev/sdh"
  volume_id    = aws_ebs_volume.gp3_volume_wazuh-indexer.id
  instance_id  = module.ec2_wazuh-indexer-01.id
  force_detach = true
}
