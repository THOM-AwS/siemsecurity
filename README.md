# siemsecurity
ecs siem

## setup grafana
grafana server
history
  sudo yum update -y
  sudo vim /etc/yum.repos.d/grafana.repo
  sudo yum install grafana -y
  sudo systemctl daemon-reload
  sudo systemctl grafana status
  sudo systemctl status grafana
  sudo systemctl status grafana-server
  lsblk
  sudo mkfs -t ext4 /dev/xvdh
  sudo mkdir /var/lib/grafana
  cd /var/lib/grafana/
  ls
  ls -lah
  sudo mount /dev/xvdh /var/lib/grafana
  sudo cp /etc/fstab /etc/fstab.orig
  echo '/dev/xvdh /var/lib/grafana ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
  sudo chown -R grafana:grafana /var/lib/grafana
  sudo chmod -R 775 /var/lib/grafana
  sudo systemctl start grafana-server
  sudo systemctl enable grafana-server.service

## setup prometheus
# Update Your System
sudo yum update -y

# Download Prometheus
cd /tmp
curl -LO https://github.com/prometheus/prometheus/releases/download/v2.33.5/prometheus-2.33.5.linux-amd64.tar.gz
tar -xvf prometheus-2.33.5.linux-amd64.tar.gz

# Install Prometheus
sudo mv prometheus-2.33.5.linux-amd64/prometheus /usr/local/bin/
sudo mv prometheus-2.33.5.linux-amd64/promtool /usr/local/bin/

# Create User and Directories
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

# Move Configuration Files
sudo mv prometheus-2.33.5.linux-amd64/consoles /etc/prometheus
sudo mv prometheus-2.33.5.linux-amd64/console_libraries /etc/prometheus

# Create Prometheus Configuration
sudo bash -c 'cat <<EOF > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
EOF'

# Set Ownership
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

# Create a Systemd Service
sudo bash -c 'cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Server
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file /etc/prometheus/prometheus.yml \
  --storage.tsdb.path /var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF'

# Prepare the Volume
sudo mkfs -t ext4 /dev/xvdh
sudo mount /dev/xvdh /var/lib/prometheus
echo '/dev/xvdh /var/lib/prometheus ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
sudo chown -R prometheus:prometheus /var/lib/prometheus

# Start Prometheus
sudo systemctl daemon-reload
sudo systemctl enable prometheus.service
sudo systemctl start prometheus.service

# Verify the Installation
sudo systemctl status prometheus.service

## wazuh indexer

sudo dnf install java-21-amazon-corretto
sudo mkfs.ext4 /dev/nvme1n1
sudo mkdir -p /var/lib/wazuh-indexer
sudo mount /dev/nvme1n1 /var/lib/wazuh-indexer
echo '/dev/nvme1n1 /var/lib/wazuh-indexer ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab

# Import the Wazuh repository GPG key
sudo rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH

# Add the Wazuh repository
sudo tee /etc/yum.repos.d/wazuh.repo <<EOF
[wazuh_repo]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL-\$releasever - Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF

sudo yum install wazuh-indexer -y

# Configure Wazuh Indexer to use the mounted volume for data (Already set by default to /var/lib/wazuh-indexer)

# Enable and start the Wazuh Indexer service
sudo systemctl daemon-reload
sudo systemctl enable wazuh-indexer.service
sudo systemctl start wazuh-indexer.service



CERT_DIR="/etc/wazuh-indexer/certs"
sudo mkdir -p $CERT_DIR

cd $CERT_DIR

sudo openssl genpkey -algorithm RSA -out wazuh-indexer.key -pkeyopt rsa_keygen_bits:2048

sudo openssl req -new -key wazuh-indexer.key -out wazuh-indexer.csr -subj "/C=US/ST=YourState/L=YourCity/O=YourOrganization/OU=YourUnit/CN=wazuh-indexer"

sudo openssl x509 -signkey wazuh-indexer.key -in wazuh-indexer.csr -req -days 365 -out wazuh-indexer.crt

sudo cp wazuh-indexer.crt indexer.pem
sudo cp wazuh-indexer.key indexer-key.pem

OPENSEARCH_CONF="/etc/wazuh-indexer/opensearch.yml"
if [ -f "$OPENSEARCH_CONF" ]; then
    sudo cp $OPENSEARCH_CONF $OPENSEARCH_CONF.backup

    # Append or modify the SSL configuration
    # Ensure these configurations match your setup, especially if you're integrating with Wazuh or other plugins
    echo "plugins.security.ssl.transport.pemcert_filepath: $CERT_DIR/indexer.pem" | sudo tee -a $OPENSEARCH_CONF
    echo "plugins.security.ssl.transport.pemkey_filepath: $CERT_DIR/indexer-key.pem" | sudo tee -a $OPENSEARCH_CONF
    echo "plugins.security.ssl.transport.pemtrustedcas_filepath: $CERT_DIR/indexer.pem" | sudo tee -a $OPENSEARCH_CONF

    # Restart Wazuh Indexer (OpenSearch) to apply changes
    sudo systemctl restart wazuh-indexer.service

    echo "Wazuh Indexer (OpenSearch) has been configured to use SSL with self-signed certificates."
else
    echo "OpenSearch configuration file not found at $OPENSEARCH_CONF. Please check the path and try again."
fi

