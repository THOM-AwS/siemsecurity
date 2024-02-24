module "ec2_wazuh" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "3.0.0"

  name = "wazuh"

  ami                    = "ami-09ccb67fcbf1d625c"
  instance_type          = "c5.xlarge"
  subnet_id              = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.all.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  root_block_device = [
    {
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
    # Commands to install Wazuh and Let's Encrypt certbot
    # Update and install necessary packages
    apt-get update && apt-get upgrade -y
    apt-get install -y wget apt-transport-https lsb-release gnupg curl

    # Install Wazuh manager
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -
    echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list
    apt-get update
    apt-get install -y wazuh-manager

    # Install and configure Let's Encrypt certbot (HTTP challenge)
    apt-get install -y certbot python3-certbot-apache
    certbot --apache -d 127cyber.com --non-interactive --agree-tos -m your@email.com --redirect
  EOF
}
