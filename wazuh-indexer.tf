module "ec2_wazuh" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "3.0.0"

  name = "wazuh"

  ami                    = "ami-09ccb67fcbf1d625c"
  instance_type          = "c5.xlarge"
  subnet_id              = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.all.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  key_name               = data.aws_key_pair.tom.key_name

  root_block_device = [
    {
      encrypted   = "true"
      kms_key_id  = aws_kms_key.siem_key.id
      volume_type = "gp3"
      volume_size = 100
    },
  ]

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }

  user_data = <<-TEOF
#!/bin/bash
yum update -y
yum install -y wget curl amazon-linux-extras python-pip htop java-devel
pip install certbot_dns_route53
amazon-linux-extras install epel -y

INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
NODE_NAME=$(hostname)


# Install and configure Let's Encrypt certbot
yum install -y certbot python3-certbot-dns-route53
certbot certonly --dns-route53 -d 127cyber.com -d wazuh.127cyber.com -d listen.127cyber.com --non-interactive --agree-tos -m thomas_hamer@outlook.com --server https://acme-v02.api.letsencrypt.org/directory --cert-name 127cyber.com
certbot certonly --dns-route53 -d admin.127cyber.com --non-interactive --agree-tos -m thomas_hamer@outlook.com --server https://acme-v02.api.letsencrypt.org/directory --cert-name admin.127cyber.com
(crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/certbot renew --quiet") | crontab -

# Install Wazuh indexer and manager
rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
cat > /etc/yum.repos.d/wazuh.repo <<IEOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
IEOF
yum -y install wazuh-indexer wazuh-manager wazuh-dashboard

# Node configuration
mkdir -p /etc/wazuh-indexer/certs
cp /etc/letsencrypt/live/admin.127cyber.com/fullchain.pem /etc/wazuh-indexer/certs/admin.pem
cp /etc/letsencrypt/live/admin.127cyber.com/privkey.pem /etc/wazuh-indexer/certs/admin-key.pem
cp /etc/letsencrypt/live/127cyber.com/fullchain.pem /etc/wazuh-indexer/certs/indexer.pem
cp /etc/letsencrypt/live/127cyber.com/privkey.pem /etc/wazuh-indexer/certs/indexer-key.pem
cat /etc/letsencrypt/live/127cyber.com/fullchain.pem > /etc/wazuh-indexer/certs/root-ca.pem
chmod 500 /etc/wazuh-indexer/certs
chmod 444 /etc/wazuh-indexer/certs/*
chown -R wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/certs
sed -i '/\[Service\]/a LimitMEMLOCK=infinity' /usr/lib/systemd/system/wazuh-indexer.service
sed -i 's/-Xms1g/-Xms4g/g' /etc/wazuh-indexer/jvm.options
sed -i 's/-Xmx1g/-Xmx4g/g' /etc/wazuh-indexer/jvm.options

mkdir -p /etc/wazuh-dashboard/certs
cp /etc/letsencrypt/live/127cyber.com/fullchain.pem /etc/wazuh-dashboard/certs/dashboard.pem
cp /etc/letsencrypt/live/127cyber.com/privkey.pem /etc/wazuh-dashboard/certs/dashboard-key.pem
cat /etc/letsencrypt/live/127cyber.com/fullchain.pem > /etc/wazuh-dashboard/certs/root-ca.pem
chmod 500 /etc/wazuh-dashboard/certs
chmod 444 /etc/wazuh-dashboard/certs/*
chown -R wazuh-dashboard:wazuh-dashboard /etc/wazuh-dashboard/certs

# /var/ossec/etc/ossec.conf
sed -i "s/NODE_IP/$INSTANCE_IP/g" /var/ossec/etc/ossec.conf

# /etc/wazuh-indexer/opensearch.yml
sed -i "s/wazuh-cluster/127cyber/g" /etc/wazuh-indexer/opensearch.yml
sed -i "s/#discovery.seed_hosts:/discovery.seed_hosts:/g" /etc/wazuh-indexer/opensearch.yml
sed -i "s/#  - \"node-1-ip\"/ - \"$INSTANCE_IP\"/g" /etc/wazuh-indexer/opensearch.yml
sed -i "s/\"node-1\"/\"$NODE_NAME\"/g" /etc/wazuh-indexer/opensearch.yml
echo -e "\nbootstrap.memory_lock: true" | sudo tee -a /etc/wazuh-indexer/opensearch.yml
sed -i "s/CN=admin,OU=Wazuh,O=Wazuh,L=California,C=US/CN=127cyber.com/g" /etc/wazuh-indexer/opensearch.yml
sed -i "s/CN=,OU=Wazuh,O=Wazuh,L=California,C=US/CN=127cyber.com/g" /etc/wazuh-indexer/opensearch.yml

# /etc/wazuh-dashboard/opensearch_dashboards.yml
sed -i "s/localhost/wazuh.127cyber.com/g" /etc/wazuh-indexer/opensearch.yml

# java keystore
wget -O /tmp/letsencrypt.pem https://letsencrypt.org/certs/isrgrootx1.pem
sudo keytool -import -trustcacerts -alias letsencrypt -file /tmp/letsencrypt.pem -keystore $(/usr/bin/java -XshowSettings:properties -version 2>&1 >/dev/null | grep 'java.home' | awk '{print $3}')/lib/security/cacerts <<< changeit

systemctl daemon-reload

# start Wazuh services
systemctl enable wazuh-indexer 
systemctl enable wazuh-manager
systemctl enable wazuh-dashboard
systemctl start wazuh-indexer 
systemctl start wazuh-manager
systemctl start wazuh-dashboard

JAVA_HOME=/usr/share/wazuh-indexer/jdk runuser wazuh-indexer --shell=/bin/bash --command="cd /etc/wazuh-indexer/opensearch-security && /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh -cacert /etc/wazuh-indexer/certs/root-ca.pem -cert /etc/wazuh-indexer/certs/admin.pem -key /etc/wazuh-indexer/certs/admin-key.pem -h 127.0.0.1 -p 9200 -icl -nhnv"
  TEOF
}
