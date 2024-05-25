locals {
  monitoring-script = <<-EOF
#!/bin/bash

sudo apt update -y

# Make prometheus user
sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Prometheus Monitoring User" prometheus

# Make directories and dummy files necessary for prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo touch /etc/prometheus/prometheus.yml
sudo touch /etc/prometheus/prometheus.rules.yml

# Assign ownership of the files above to prometheus user
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

# Download prometheus and copy utilities to where they should be in the filesystem
wget https://github.com/prometheus/prometheus/releases/download/v2.45.5/prometheus-2.45.5.linux-amd64.tar.gz
tar xvzf prometheus*.tar.gz

sudo cp prometheus-2.45.5.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-2.45.5.linux-amd64/promtool /usr/local/bin/
sudo cp -r prometheus-2.45.5.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-2.45.5.linux-amd64/console_libraries /etc/prometheus

# Assign the ownership of the tools above to prometheus user
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

# Populate configuration files 
sudo cat <<EOT> /etc/prometheus/prometheus.yml
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
           - localhost:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
   - "prometheus.rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "Infra Jenkins exporter"
    static_configs:
      - targets: ["${var.jenkins_ip}:9100"] 

  - job_name: "Infra Nexus exporter"
    static_configs:
      - targets: ["${var.nexus-ip}:9100"]

  - job_name: "Infra Sonarqube exporter"
    static_configs:
      - targets: ["${var.Sonarqube-ip}:9100"]

  - job_name: "Infra Ansible exporter"
    static_configs:
      - targets: ["${var.ansible_ip}:9100"]

  - job_name: "ec2-service-discovery"
    ec2_sd_configs:
      - region: eu-west-2
        access_key: '${aws_iam_access_key.prom_user_access_key.id}'
        secret_key: '${aws_iam_access_key.prom_user_access_key.secret}'
EOT

sudo cat <<EOT> /etc/prometheus/alert.rules.yml
groups:
  - name: ServerDown
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: "critical"
        annotations:
          summary: "Endpoint {{ $labels.instance }} down"
          description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute."

      - alert: HostOutOfMemory
        expr: node_memory_MemAvailable / node_memory_MemTotal * 100 < 25
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Host out of memory (instance {{ $labels.instance }})"
          description: "Node memory is filling up (< 25% left)\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"

      - alert: HostOutOfDiskSpace
        expr: (node_filesystem_avail{mountpoint="/"} * 100) / node_filesystem_size{mountpoint="/"} < 50
        for: 1s
        labels:
          severity: warning
        annotations:
          summary: "Host out of disk space (instance {{ $labels.instance }})"
          description: "Disk is almost full (< 50% left)\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"

      - alert: HostHighCpuLoad
        expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Host high CPU load (instance {{ $labels.instance }})"
          description: "CPU load is > 80%\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"
EOT

sudo cat <<EOT> /etc/systemd/system/prometheus.service
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
# systemd
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# Installation cleanup
rm prometheus-2.45.5.linux-amd64.tar.gz
rm -rf prometheus-2.45.5.linux-amd64


# Make node_exporter user
sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Node Exporter User" node_exporter

# Download node_exporter and copy utilities to where they should be in the filesystem
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.0/node_exporter-1.8.0.linux-amd64.tar.gz
tar xvzf node_exporter-1.8.0.linux-amd64.tar.gz

sudo cp node_exporter-1.8.0.linux-amd64/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# systemd
sudo cat <<EOT> /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

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

# Installation cleanup
rm node_exporter-1.8.0.linux-amd64.tar.gz
rm -rf node_exporter-1.8.0.linux-amd64


# install grafana
sudo apt update
sudo apt install -y gnupg2 curl software-properties-common
curl -fsSL https://packages.grafana.com/gpg.key|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/grafana.gpg
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
sudo apt update
sudo apt -y install grafana
sudo systemctl enable --now grafana-server


#Alertmanager
# Make alertmanager user
sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Alertmanager User" alertmanager

# Make directories and dummy files necessary for alertmanager
sudo mkdir /etc/alertmanager
sudo mkdir /etc/alertmanager/template
sudo mkdir -p /var/lib/alertmanager/data
sudo touch /etc/alertmanager/alertmanager.yml


sudo chown -R alertmanager:alertmanager /etc/alertmanager
sudo chown -R alertmanager:alertmanager /var/lib/alertmanager

# Download alertmanager and copy utilities to where they should be in the filesystem
#VERSION=0.27.0
wget https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
tar xvzf alertmanager-0.27.0.linux-amd64.tar.gz

sudo cp alertmanager-0.27.0.linux-amd64/alertmanager /usr/local/bin/
sudo cp alertmanager-0.27.0.linux-amd64/amtool /usr/local/bin/
sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager
sudo chown alertmanager:alertmanager /usr/local/bin/amtool

sudo cat <<EOT> /etc/alertmanager/alertmanager.yml
global:
  resolve_timeout: 1m
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'tunde.afod@gmail.com'
  smtp_auth_username: 'tunde.afod@gmail.com'
  smtp_auth_password: '{{ env "SMTP_AUTH_PASSWORD" }}'
  smtp_require_tls: true

templates:
- '/etc/alertmanager/template/*.tmpl'

route:
  repeat_interval: 3h
  receiver: email-notifications

receivers:
- name: 'email-notifications'
  email_configs:
  - to: 'tunde.afod@gmail.com'
EOT

sudo cat <<EOT> /etc/systemd/system/alertmanager.service
[Unit]
Description=Prometheus Alert Manager service
Wants=network-online.target
After=network.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
    --config.file /etc/alertmanager/alertmanager.yml \
    --storage.path /var/lib/alertmanager/data
Restart=always

[Install]
WantedBy=multi-user.target
EOT

# systemd
sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager

# Installation cleanup
rm alertmanager-0.27.0.linux-amd64.tar.gz
rm -rf alertmanager-0.27.0.linux-amd64

sudo hostnamectl set-hostname monitoring
EOF
}