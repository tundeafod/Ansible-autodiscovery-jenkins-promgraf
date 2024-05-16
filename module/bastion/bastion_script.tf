locals {
  bastion_user_data = <<-EOF
#!/bin/bash
echo "${var.private_key}" >> /home/ec2-user/.ssh/id_rsa
chmod 400 /home/ec2-user/.ssh/id_rsa
chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa

# create node exporter user
sudo useradd --no-create-home node_exporter

# download node_exporter tar file
sudo yum install wget -y
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xzf node_exporter-1.6.1.linux-amd64.tar.gz
cd node_exporter-1.6.1.linux-amd64
sudo cp node_exporter /usr/local/bin
cd ..
rm -rf node_exporter-1.6.1.linux-amd64.tar.gz node_exporter-1.6.1.linux-amd64
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# create node_exporter service file to start node_exporter
sudo cat <<EOT>> /etc/systemd/system/node_exporter.service

EOT

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

sudo hostnamectl set-hostname Bastion

EOF
}