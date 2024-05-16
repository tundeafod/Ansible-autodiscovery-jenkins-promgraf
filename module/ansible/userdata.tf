locals {
  ansible-user-data = <<-EOF
#!/bin/bash
#Update instance and install tools (get, unzip, aws cli) 
sudo yum update -y
sudo yum install wget -y
sudo yum install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo ln -svf /usr/local/bin/aws /usr/bin/aws #This command is often used to make the AWS Command Line Interface (AWS CLI) available globally by creating a symbolic link in a directory that is included in the system's PATH
sudo bash -c 'echo "StrictHostKeyChecking No" >> /etc/ssh/ssh_config'
#configuring awscli on the ansible server
sudo su -c "aws configure set aws_access_key_id ${aws_iam_access_key.ansible_user_key.id}" ec2-user
sudo su -c "aws configure set aws_secret_access_key ${aws_iam_access_key.ansible_user_key.secret}" ec2-user
sudo su -c "aws configure set default.region eu-west-2" ec2-user
sudo su -c "aws configure set default.output text" ec2-user

# Set Access_keys as ENV Variables
export AWS_ACCESS_KEY_ID=${aws_iam_access_key.ansible_user_key.id}
export AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.ansible_user_key.secret}

# install ansible
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum install epel-release-latest-7.noarch.rpm -y
sudo yum update -y
sudo yum install python python-devel python-pip ansible -y

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

# copying files from local machines into Ansible server
sudo echo "${file(var.staging-MyPlaybook)}" >> /etc/ansible/stage-playbook.yml 
sudo echo "${file(var.staging-discovery-script)}" >> /etc/ansible/stage-bash-script.sh
sudo echo "${file(var.prod-MyPlaybook)}" >> /etc/ansible/prod-playbook.yml
sudo echo "${file(var.prod-discovery-script)}" >> /etc/ansible/prod-bash-script.sh 
sudo echo "${var.private_key}" >> /home/ec2-user/.ssh/id_rsa
sudo bash -c 'echo "NEXUS_IP: ${var.nexus-ip}:8085" > /etc/ansible/ansible_vars_file.yml'

# Give the right permissions to the files copied from the local machine into the ansible server
sudo chown -R ec2-user:ec2-user /etc/ansible
sudo chmod 400 /etc/ansible/key.pem
sudo chmod 755 /etc/ansible/stage-bash-script.sh 
sudo chmod 755 /etc/ansible/prod-bash-script.sh

#creating crontab to execute auto discovery script
echo "* * * * * ec2-user sh /etc/ansible/stage-bash-script.sh" > /etc/crontab
echo "* * * * * ec2-user sh /etc/ansible/prod-bash-script.sh" >> /etc/crontab
sudo hostnamectl set-hostname Ansible
EOF
}


