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

    sudo mkfs -t ext4 /dev/xvdh
    2  sudo mkdir /var/lib/wazuh
    3*
    4  sudo mount /dev/xvdh /var/lib/wazuh
    5  echo '/dev/xvdh /var/lib/wazuh ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
    