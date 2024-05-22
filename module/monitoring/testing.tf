# locals {
#   monitoring-script = <<-EOF
# #!/bin/bash

# # Define variables
# PROMVERSION=2.45.5
# NODEVERSION=1.8.0
# ALERTMANAGERVERSION=0.27.0

# sudo apt update -y
# # Make prometheus user
# sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Prometheus Monitoring User" prometheus

# # Make directories and dummy files necessary for prometheus
# sudo mkdir /etc/prometheus
# sudo mkdir /var/lib/prometheus
# sudo touch /etc/prometheus/prometheus.yml
# sudo touch /etc/prometheus/prometheus.rules.yml

# # Assign ownership of the files above to prometheus user
# sudo chown -R prometheus:prometheus /etc/prometheus
# sudo chown prometheus:prometheus /var/lib/prometheus

# # Download prometheus and copy utilities to where they should be in the filesystem
# #VERSION=2.45.5
# wget //github.com/prometheus/prometheus/releases/download/v${PROMVERSION}/prometheus-${PROMVERSION}.linux-amd64.tar.gz
# tar xvzf prometheus-${PROMVERSION}.linux-amd64.tar.gz

# sudo cp prometheus-${PROMVERSION}.linux-amd64/prometheus /usr/local/bin/
# sudo cp prometheus-${PROMVERSION}.linux-amd64/promtool /usr/local/bin/
# sudo cp -r prometheus-${PROMVERSION}.linux-amd64/consoles /etc/prometheus
# sudo cp -r prometheus-${PROMVERSION}.linux-amd64/console_libraries /etc/prometheus

# # Assign the ownership of the tools above to prometheus user
# sudo chown -R prometheus:prometheus /etc/prometheus/consoles
# sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
# sudo chown prometheus:prometheus /usr/local/bin/prometheus
# sudo chown prometheus:prometheus /usr/local/bin/promtool

# # Populate configuration files 
# sudo tee /etc/prometheus/prometheus.yml > /dev/null <<EOT
# global:
#   scrape_interval: 15s

# rule_files:
#   - 'prometheus.rules.yml'

# scrape_configs:

#   - job_name: 'prometheus'
#     scrape_interval: 5s
#     static_configs:
#       - targets: ['localhost:9090']

#   - job_name: 'node_exporter'
#     scrape_interval: 5s
#     static_configs:
#       - targets: ['localhost:9100']

#   - job_name: 'Infra node exporter'
#     scrape_interval: 5s
#     static_configs:
#       - targets:
#         - ['${var.nexus-ip}:9100', '${var.jenkins_ip}:9100', '${var.Sonarqube-ip}:9100', '${var.ansible_ip}:9100']

#   - job_name: 'ec2-service-discovery'
#     ec2_sd_configs:
#       - region: eu-west-2
#         access_key: '${aws_iam_access_key.prom_user_access_key.id}'
#         secret_key: '${aws_iam_access_key.prom_user_access_key.secret}'

# alerting:
#   alertmanagers:
#   - static_configs:
#     - targets:
#       - localhost:9093
# EOT

# sudo tee /etc/prometheus/prometheus.rules.yml > /dev/null <<EOT
# groups:
#   - name: ServerDown
#     rules:
#       - alert: InstanceDown
#         expr: up == 0
#         for: 1m
#         labels:
#           severity: "critical"
#         annotations:
#           summary: "Endpoint {{ $labels.instance }} down"
#           description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minutes."
        
#       - alert: HostOutOfMemory
#         expr: node_memory_MemAvailable / node_memory_MemTotal * 100 < 25
#         for: 2m
#         labels:
#           severity: warning
#         annotations:
#           summary: "Host out of memory (instance {{ $labels.instance }})"
#           description: "Node memory is filling up (< 25% left)\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"

#       - alert: HostOutOfDiskSpace
#         expr: (node_filesystem_avail{mountpoint="/"}  * 100) / node_filesystem_size{mountpoint="/"} < 50
#         for: 1s
#         labels:
#           severity: warning
#         annotations:
#           summary: "Host out of disk space (instance {{ $labels.instance }})"
#           description: "Disk is almost full (< 50% left)\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"

#       - alert: HostHighCpuLoad
#         expr: (sum by (instance) (irate(node_cpu{job="node_exporter_metrics",mode="idle"}[5m]))) > 80
#         for: 2m
#         labels:
#           severity: warning
#         annotations:
#           summary: "Host high CPU load (instance {{ $labels.instance }})"
#           description: "CPU load is > 80%\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"
# EOT

# sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOT
# [Unit]
# Description=Prometheus
# Wants=network-online.target
# After=network-online.target

# [Service]
# User=prometheus
# Group=prometheus
# Type=simple
# ExecStart=/usr/local/bin/prometheus \
#     --config.file /etc/prometheus/prometheus.yml \
#     --storage.tsdb.path /var/lib/prometheus/ \
#     --web.console.templates=/etc/prometheus/consoles \
#     --web.console.libraries=/etc/prometheus/console_libraries

# [Install]
# WantedBy=multi-user.target
# EOT
# # systemd
# sudo systemctl daemon-reload
# sudo systemctl enable prometheus
# sudo systemctl start prometheus

# # Installation cleanup
# rm prometheus-${PROMVERSION}.linux-amd64.tar.gz
# rm -rf prometheus-${PROMVERSION}.linux-amd64


# # Make node_exporter user
# sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Node Exporter User" node_exporter

# # Download node_exporter and copy utilities to where they should be in the filesystem
# wget https://github.com/prometheus/node_exporter/releases/download/v${NODEVERSION}/node_exporter-${NODEVERSION}.linux-amd64.tar.gz
# tar xvzf node_exporter-${NODEVERSION}.linux-amd64.tar.gz

# sudo cp node_exporter-${NODEVERSION}.linux-amd64/node_exporter /usr/local/bin/
# sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# # systemd
# sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOT
# [Unit]
# Description=Node Exporter
# Wants=network-online.target
# After=network-online.target

# [Service]
# User=node_exporter
# Group=node_exporter
# Type=simple
# ExecStart=/usr/local/bin/node_exporter

# [Install]
# WantedBy=multi-user.target
# EOT

# sudo systemctl daemon-reload
# sudo systemctl enable node_exporter
# sudo systemctl start node_exporter

# # Installation cleanup
# rm node_exporter-${NODEVERSION}.linux-amd64.tar.gz
# rm -rf node_exporter-${NODEVERSION}.linux-amd64


# # install grafana
# sudo apt update
# sudo apt install -y gnupg2 curl software-properties-common
# curl -fsSL https://packages.grafana.com/gpg.key|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/grafana.gpg
# sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
# sudo apt update
# sudo apt -y install grafana
# sudo systemctl enable --now grafana-server


# #Alertmanager
# # Make alertmanager user
# sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Alertmanager User" alertmanager

# # Make directories and dummy files necessary for alertmanager
# sudo mkdir /etc/alertmanager
# sudo mkdir /etc/alertmanager/template
# sudo mkdir -p /var/lib/alertmanager/data
# sudo touch /etc/alertmanager/alertmanager.yml


# sudo chown -R alertmanager:alertmanager /etc/alertmanager
# sudo chown -R alertmanager:alertmanager /var/lib/alertmanager

# # Download alertmanager and copy utilities to where they should be in the filesystem
# #VERSION=0.27.0
# wget https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGERVERSION}/alertmanager-${ALERTMANAGERVERSION}.linux-amd64.tar.gz
# tar xvzf alertmanager-${ALERTMANAGERVERSION}.linux-amd64.tar.gz

# sudo cp alertmanager-${ALERTMANAGERVERSION}.linux-amd64/alertmanager /usr/local/bin/
# sudo cp alertmanager-${ALERTMANAGERVERSION}.linux-amd64/amtool /usr/local/bin/
# sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager
# sudo chown alertmanager:alertmanager /usr/local/bin/amtool

# # Populate configuration files
# cat ./alertmanager/alertmanager.yml | sudo tee /etc/alertmanager/alertmanager.yml
# cat ./alertmanager/alertmanager.service | sudo tee /etc/systemd/system/alertmanager.service

# sudo tee /etc/alertmanager/alertmanager.yml > /dev/null <<EOT
# global:
#   resolve_timeout: 1m
#   smtp_smarthost: 'smtp.gmail.com:587'
#   smtp_from: 'tunde.afod@gmail.com'
#   smtp_auth_username: 'tunde.afod@gmail.com'
#   smtp_auth_password: 'Babatunde17'
#   smtp_require_tls: true

# templates:
# - '/etc/alertmanager/template/*.tmpl'

# route:
#   repeat_interval: 3h
#   receiver: email-notifications

# receivers:
# - name: 'email-notifications'
#   email_configs:
#   - to: 'tunde.afod@gmail.com'
# EOT

# sudo tee /etc/systemd/system/alertmanager.service > /dev/null <<EOT
# [Unit]
# Description=Prometheus Alert Manager service
# Wants=network-online.target
# After=network.target

# [Service]
# User=alertmanager
# Group=alertmanager
# Type=simple
# ExecStart=/usr/local/bin/alertmanager \
#     --config.file /etc/alertmanager/alertmanager.yml \
#     --storage.path /var/lib/alertmanager/data
# Restart=always

# [Install]
# WantedBy=multi-user.target
# EOT

# # systemd
# sudo systemctl daemon-reload
# sudo systemctl enable alertmanager
# sudo systemctl start alertmanager

# # Installation cleanup
# rm alertmanager-${ALERTMANAGERVERSION}.linux-amd64.tar.gz
# rm -rf alertmanager-${ALERTMANAGERVERSION}.linux-amd64

# sudo hostnamectl set-hostname monitoring
# EOF
# }