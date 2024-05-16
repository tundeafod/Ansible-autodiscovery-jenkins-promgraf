#!/bin/bash

# Update system, install Docker and its dependencies
sudo yum update -y
sudo yum upgrade -y
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce -y

# Add a registry to the Docker daemon configuration to allow insecure communication (without TLS verification) with a Docker registry on port 8085
sudo cat <<EOT>> /etc/docker/daemon.json
{
  "insecure-registries" : ["${nexus-ip}:8085"]
}
EOT

# Starts the Docker service and enables it to run on boot.
# Add the ec2-user to the docker group, allowing them to run Docker commands.
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Create a shell script that manages a Docker container on the EC2 instance, pulling updates from a Nexus registry
sudo mkdir -p /home/ec2-user/scripts
cat << EOF > "/home/ec2-user/scripts/script.sh"
#!/bin/bash

set -e

# Define Variables
IMAGE_NAME="${nexus-ip}:8085/petclinicapps"
CONTAINER_NAME="appContainer"
NEXUS_IP="${nexus-ip}:8085"

# Function to Login to dockerhub
authenticate_docker() {
    docker login --username=admin --password=admin123 \$NEXUS_IP
}

# Function to check for latest image on dockerhub
check_for_updates() {
    docker pull \$IMAGE_NAME &> /dev/null
}

# Function to stop and remove the current container
# Function to deploy image in a container
update_container() {
    docker stop \$CONTAINER_NAME || true
    docker rm \$CONTAINER_NAME || true
    docker run -d --name \$CONTAINER_NAME -p 8080:8080 \$IMAGE_NAME
}

# Main Function
main() {
    authenticate_docker
    check_for_updates
    update_container
}
main
EOF

sudo chmod 777 /home/ec2-user/scripts/script.sh
sudo chown ec2-user:ec2-user /home/ec2-user/scripts/script.sh

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


sudo systemctl restart docker
sudo hostnamectl set-hostname production-instance
