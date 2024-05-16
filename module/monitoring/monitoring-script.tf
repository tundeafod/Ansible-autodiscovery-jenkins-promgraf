locals {
  monitoring-script = <<-EOF
#!/bin/bash

sudo apt update

# create a group and user 
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

# download the prometheus tar file for the internet and configure it
wget https://github.com/prometheus/prometheus/releases/download/v2.43.0/prometheus-2.43.0.linux-amd64.tar.gz
tar vxf prometheus*.tar.gz
cd prometheus-2.43.0.linux-amd64
sudo mv prometheus /usr/local/bin
sudo mv promtool /usr/local/bin
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo mv consoles /etc/prometheus
sudo mv console_libraries /etc/prometheus
sudo mv prometheus.yml /etc/prometheus

sudo chown prometheus:prometheus /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
sudo chown -R prometheus:prometheus /var/lib/prometheus

cd
rm -rf prometheus-2.43.0.linux-amd64.tar.gz prometheus-2.43.0.linux-amd64

sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
sudo chown -R prometheus:prometheus /var/lib/prometheus

# create prometheus service file to start prometheus
sudo cat <<EOT>> /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
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
EOT

# create prometheus config file
sudo cat <<EOT> /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  external_labels:
    monitor: 'prometheus'

scrape_configs:
  - job_name: 'Infra node exporter'
    static_configs:
      - targets: ['localhost:9100', '${var.nexus-ip}:9100', '${var.jenkins_ip}:9100', '${var.Sonarqube-ip}:9100', '${var.ansible_ip}:9100']
EOT

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# create node exporter user
sudo useradd --no-create-home node_exporter

# download node_exporter tar file
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xzf node_exporter-1.6.1.linux-amd64.tar.gz
cd node_exporter-1.6.1.linux-amd64
sudo cp node_exporter /usr/local/bin
cd ..
rm -rf node_exporter-1.6.1.linux-amd64.tar.gz node_exporter-1.6.1.linux-amd64
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# create node_exporter service file to start node_exporter
sudo cat <<EOT>> /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter Service
After=network.target

[Service]
User=node_exporter  
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOT

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter


curl http://localhost:9100/metrics

# install grafana
sudo apt update
sudo apt install -y gnupg2 curl software-properties-common
curl -fsSL https://packages.grafana.com/gpg.key|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/grafana.gpg
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
sudo apt update
sudo apt -y install grafana
sudo systemctl enable --now grafana-server

# copying files from local machines into Prometheus server
sudo echo "${file(var.prom_server_discovery-script)}" >> /etc/prometheus/prom_server_update.sh 
sudo echo "${var.private_key}" >> /home/ubuntu/.ssh/id_rsa


# Give the right permissions to the files copied from the local machine into the Prometheus server
sudo chown -R ubuntu:ubuntu /etc/prometheus
sudo chmod 400 /etc/prometheus/key.pem
sudo chmod 755 /etc/prometheus/prom_server_update.sh

#creating crontab to execute auto discovery script
echo "* * * * * ubuntu sh /etc/prometheus/prom_server_update.sh.sh" >> /etc/crontab

sudo hostnamectl set-hostname monitoring
EOF
}


