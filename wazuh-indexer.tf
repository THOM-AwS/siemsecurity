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
yum install -y wget curl amazon-linux-extras python-pip htop
pip install certbot_dns_route53
amazon-linux-extras install epel -y

INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# # Install and configure Let's Encrypt certbot
# yum install -y certbot python3-certbot-dns-route53
# certbot certonly --dns-route53 -d 127cyber.com -d wazuh.127cyber.com -d listen.127cyber.com --non-interactive --agree-tos -m thomas_hamer@outlook.com --test-cert
# (crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/certbot renew --quiet") | crontab -

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
NODE_NAME=$(hostname)
mkdir -p /etc/wazuh-indexer/certs
# cp /etc/letsencrypt/live/127cyber.com/fullchain.pem /etc/wazuh-indexer/certs/indexer.pem
# wget -O /etc/wazuh-indexer/certs/root-ca.pem https://letsencrypt.org/certs/isrgrootx1.pem
# cp /etc/letsencrypt/live/127cyber.com/privkey.pem /etc/wazuh-indexer/certs/indexer-key.pem
# chmod 500 /etc/wazuh-indexer/certs
# chmod 400 /etc/wazuh-indexer/certs/*
# chown -R wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/certs
sed -i '/\[Service\]/a LimitMEMLOCK=infinity' /usr/lib/systemd/system/wazuh-indexer.service
sed -i 's/-Xms1g/-Xms4g/g' /etc/wazuh-indexer/jvm.options
sed -i 's/-Xmx1g/-Xmx4g/g' /etc/wazuh-indexer/jvm.options

mkdir -p /etc/wazuh-dashboard/certs
# cp /etc/letsencrypt/live/127cyber.com/fullchain.pem /etc/wazuh-dashboard/certs/indexer.pem
# wget -O /etc/wazuh-dashboard/certs/root-ca.pem https://letsencrypt.org/certs/isrgrootx1.pem
# cp /etc/letsencrypt/live/127cyber.com/privkey.pem /etc/wazuh-dashboard/certs/indexer-key.pem
# chmod 500 /etc/wazuh-dashboard/certs
# chmod 400 /etc/wazuh-dashboard/certs/*
# chown -R wazuh-dashboard:wazuh-dashboard /etc/wazuh-dashboard/certs

sed -i "s/NODE_NAME/$INSTANCE_IP/g" /var/ossec/etc/ossec.conf

# tee /etc/wazuh-indexer/opensearch.yml << EOF
# network.host: "0.0.0.0"
# node.name: "$NODE_NAME"
# cluster.initial_master_nodes:
# - "$NODE_NAME"
# cluster.name: "127cyber"
# discovery.seed_hosts:
# - "$NODE_NAME"
# node.max_local_storage_nodes: "3"
# path.data: /var/lib/wazuh-indexer
# path.logs: /var/log/wazuh-indexer

# bootstrap.memory_lock: true

# plugins.security.ssl.http.pemcert_filepath: /etc/wazuh-indexer/certs/indexer.pem
# plugins.security.ssl.http.pemkey_filepath: /etc/wazuh-indexer/certs/indexer-key.pem
# plugins.security.ssl.http.pemtrustedcas_filepath: /etc/wazuh-indexer/certs/root-ca.pem
# plugins.security.ssl.transport.pemcert_filepath: /etc/wazuh-indexer/certs/indexer.pem
# plugins.security.ssl.transport.pemkey_filepath: /etc/wazuh-indexer/certs/indexer-key.pem
# plugins.security.ssl.transport.pemtrustedcas_filepath: /etc/wazuh-indexer/certs/root-ca.pem
# plugins.security.ssl.http.enabled: true
# plugins.security.ssl.transport.enforce_hostname_verification: false
# plugins.security.ssl.transport.resolve_hostname: false

# plugins.security.authcz.admin_dn:
# - "CN=127cyber.com"
# plugins.security.check_snapshot_restore_write_privileges: true
# plugins.security.enable_snapshot_restore_privilege: true
# plugins.security.nodes_dn:
# - "CN=127cyber.com"
# plugins.security.restapi.roles_enabled:
# - "all_access"
# - "security_rest_api_access"

# plugins.security.system_indices.enabled: true
# plugins.security.system_indices.indices: [".plugins-ml-model", ".plugins-ml-task", ".opendistro-alerting-config", ".opendistro-alerting-alert*", ".opendistro-anomaly-results*", ".opendistro-anomaly-detector*", ".opendistro-anomaly-checkpoints", ".opendistro-anomaly-detection-state", ".opendistro-reports-*", ".opensearch-notifications-*", ".opensearch-notebooks", ".opensearch-observability", ".opendistro-asynchronous-search-response*", ".replication-metadata-store"]

# ### Option to allow Filebeat-oss 7.10.2 to work ###
# #compatibility.override_main_response_version: true

# EOF

# tee /etc/wazuh-dashboard/opensearch_dashboards.yml << EOF
# server.host: "0.0.0.0"
# server.port: 443
# opensearch.hosts: "https://wazuh.127cyber.com:9200"
# opensearch.ssl.verificationMode: "certificate"
# opensearch.requestHeadersWhitelist: ["securitytenant","Authorization"]
# opensearch_security.multitenancy.enabled: false
# opensearch_security.readonly_mode.roles: ["kibana_read_only"]
# server.ssl.enabled: true
# server.ssl.key: "/etc/wazuh-dashboard/certs/indexer-key.pem"
# server.ssl.certificate: "/etc/wazuh-dashboard/certs/indexer.pem"
# opensearch.ssl.certificateAuthorities: ["/etc/wazuh-dashboard/certs/root-ca.pem"]
# uiSettings.overrides.defaultRoute: "/app/wazuh"
# EOF

systemctl daemon-reload

# start Wazuh services
systemctl enable wazuh-indexer 
systemctl enable wazuh-manager
systemctl enable wazuh-dashboard
systemctl start wazuh-indexer 
systemctl start wazuh-manager
systemctl start wazuh-dashboard

# JAVA_HOME=/usr/share/wazuh-indexer/jdk runuser wazuh-indexer --shell=/bin/bash --command="/usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh" -cd /etc/wazuh-indexer/opensearch-security -cacert /etc/wazuh-indexer/certs/root-ca.pem -cert /etc/wazuh-indexer/certs/indexer.pem -key /etc/wazuh-indexer/certs/indexer-key.pem -h 127.0.0.1 -p 9200 -icl -nhnv


  TEOF
}
