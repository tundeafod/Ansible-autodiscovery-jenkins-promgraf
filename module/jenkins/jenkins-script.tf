locals {
  jenkins_user_data = <<-EOF
#!/bin/bash
sudo yum update -y
sudo yum install git -y
sudo yum install maven -y
sudo yum install wget -y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade
sudo yum install java-17-openjdk -y
sudo yum install jenkins -y
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce -y
sudo service docker start
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
sudo usermod -aG docker jenkins
sudo chmod 777 /var/run/docker.sock
sudo cat <<EOT>> /etc/docker/daemon.json
{
  "insecure-registries" : ["${var.nexus-ip}:8085"]
}
EOT
sudo systemctl restart docker

# # Install trivy for container scanning
# RELEASE_VERSION=$(grep -Po '(?<=VERSION_ID=")[0-9]' /etc/os-release)
# cat << EOT | sudo tee -a /etc/yum.repos.d/trivy.repo
# [trivy]
# name=Trivy repository
# baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$RELEASE_VERSION/\$basearch/
# gpgcheck=0
# enabled=1
# EOT
# sudo yum -y update
# sudo yum -y install trivy

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

sudo hostnamectl set-hostname jenkins

EOF
}