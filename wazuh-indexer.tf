module "ec2_wazuh" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "3.0.0"

  name = "wazuh"

  disable_api_termination = true

  ami                    = "ami-09c8d5d747253fb7a" // Ubuntu 20.04
  instance_type          = "c5.xlarge"
  subnet_id              = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.all.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  root_block_device = [
    {
      encrypted   = "true"
      kms_key_id  = "arn:aws:kms:ap-southeast-2:941133421128:key/0ecbd38c-6753-4ea4-bb08-d9b62ca94086"
      volume_type = "gp3"
      volume_size = 100
    },
  ]

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }

  user_data = <<-EOF
                #!/bin/bash

                useradd -m -s /bin/bash tom
                useradd -m -s /bin/bash awais
                usermod -aG sudo tom
                usermod -aG sudo awais

                mkdir -p /home/tom/.ssh
                mkdir -p /home/awais/.ssh
                echo "${local.pubkey-tom}" >> /home/tom/.ssh/authorized_keys
                echo "${local.pubkey-awais}" >> /home/awais/.ssh/authorized_keys

                chmod 700 /home/tom/.ssh
                chmod 700 /home/awais/.ssh
                chmod 600 /home/tom/.ssh/authorized_keys
                chmod 600 /home/awais/.ssh/authorized_keys
                chown -R tom:tom /home/tom/.ssh
                chown -R awais:awais /home/awais/.ssh

                chage -d 0 tom
                chage -d 0 awais


                EOF

}
