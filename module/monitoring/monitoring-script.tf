locals {
  monitoring-script = <<-EOF
#!/bin/bash

sudo apt update

# # Update instance and install tools (wget, unzip, aws cli) 
# sudo apt install wget unzip -y
# wget "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -O "awscliv2.zip"
# unzip awscliv2.zip
# sudo ./aws/install

#configuring the aws cli on your ubuntu user
sudo su -c "aws configure set aws_access_key_id ${aws_iam_access_key.prom_user_access_key.id}" ubuntu
sudo su -c "aws configure set aws_secret_access_key ${aws_iam_access_key.prom_user_access_key.secret}" ubuntu
sudo su -c "aws configure set default.region eu-west-2" ubuntu
sudo su -c "aws configure set default.output text" ubuntu

#make access key for environment variable
export AWS_ACCESS_KEY_ID=${aws_iam_access_key.prom_user_access_key.id}
export AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.prom_user_access_key.secret}
export AWS_DEFAULT_REGION=eu-west-2
export AWS_DEFAULT_OUTPUT=text

# Disable SSH strict host checking
sudo bash -c 'echo "StrictHostKeyChecking No" >> /etc/ssh/ssh_config'

# Add AWS CLI to system PATH
sudo ln -svf /usr/local/bin/aws /usr/bin/aws

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

  - job_name: 'ec2-service-discovery'
    ec2_sd_configs:
      - region: eu-west-2
        access_key: '${aws_iam_access_key.prom_user_access_key.id}'
        secret_key: '${aws_iam_access_key.prom_user_access_key.secret}'
EOT

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# create Alert Manager
# Download Prometheus AlertManager
wget https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz

#Create User
sudo groupadd -f alertmanager
sudo useradd -g alertmanager --no-create-home --shell /bin/false alertmanager
sudo mkdir -p /etc/alertmanager/templates
sudo mkdir /var/lib/alertmanager
sudo chown alertmanager:alertmanager /etc/alertmanager
sudo chown alertmanager:alertmanager /var/lib/alertmanager

# Unpack Prometheus AlertManager Binary
tar -xvf alertmanager-0.27.0.linux-amd64.tar.gz
mv alertmanager-0.27.0.linux-amd64 alertmanager-files

# Install Prometheus AlertManager
sudo cp alertmanager-files/alertmanager /usr/bin/
sudo cp alertmanager-files/amtool /usr/bin/
sudo chown alertmanager:alertmanager /usr/bin/alertmanager
sudo chown alertmanager:alertmanager /usr/bin/amtool

#Install Prometheus AlertManager Configuration File
sudo cp alertmanager-files/alertmanager.yml /etc/alertmanager/alertmanager.yml
sudo chown alertmanager:alertmanager /etc/alertmanager/alertmanager.yml

# create alertmanger service file to start Alertmanger
sudo cat <<EOT>> /usr/lib/systemd/system/alertmanager.service
[Unit]
Description=AlertManager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/bin/alertmanager \
    --config.file /etc/alertmanager/alertmanager.yml \
    --storage.path /var/lib/alertmanager/

[Install]
WantedBy=multi-user.target
EOT

sudo chmod 664 /usr/lib/systemd/system/alertmanager.service

sudo systemctl daemon-reload 
sudo systemctl start alertmanager
sudo systemctl enable alertmanager.service


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

sudo hostnamectl set-hostname monitoring
EOF
}


