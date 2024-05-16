locals {
  nexus_user_data = <<-EOF
#!/bin/bash
sudo yum update -y
sudo yum install wget -y
sudo yum install java-1.8.0-openjdk.x86_64 -y
sudo mkdir /app && cd /app
sudo wget https://download.sonatype.com/nexus/3/nexus-3.65.0-02-unix.tar.gz
sudo tar -xvf nexus-3.65.0-02-unix.tar.gz
sudo mv nexus-3.65.0-02 nexus
sudo adduser nexus
sudo chown -R nexus:nexus /app/nexus
sudo chown -R nexus:nexus /app/sonatype-work
sudo cat <<EOT> /app/nexus/bin/nexus.rc
run_as_user="nexus"
EOT
sed -i '2s/-Xms2703m/-Xms512m/' /app/nexus/bin/nexus.vmoptions
sed -i '3s/-Xmx2703m/-Xmx512m/' /app/nexus/bin/nexus.vmoptions
sed -i '4s/-XX:MaxDirectMemorySize=2703m/-XX:MaxDirectMemorySize=512m/' /app/nexus/bin/nexus.vmoptions
sudo touch /etc/systemd/system/nexus.service
sudo cat <<EOT> /etc/systemd/system/nexus.service
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=nexus
Group=nexus
ExecStart=/app/nexus/bin/nexus start
ExecStop=/app/nexus/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOT
sudo ln -s /app/nexus/bin/nexus /etc/init.d/nexus
sudo chkconfig --add nexus
sudo chkconfig --levels 345 nexus on
sudo service nexus start

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

sudo hostnamectl set-hostname Nexus
EOF
}