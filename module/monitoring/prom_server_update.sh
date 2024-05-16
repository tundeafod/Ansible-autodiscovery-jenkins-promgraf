#!/bin/bash

projectname="TSPADP"
prometheus_server_tag="$projectname-promgraf"
private_ip_file="/tmp/privateip.txt"  # Storing in /tmp directory on the server
prometheus_config="/etc/prometheus/prometheus.yml"
target_port="9100"
sleep_duration=60
SSH_KEY_PATH="/home/ubuntu/.ssh/id_rsa"  # Change 'your_username' to your actual username


while true; do
    # Step 1: AWS CLI login

    aws configure set aws_access_key_id "${aws_iam_access_key.prom_user_access_key.id}"
    aws configure set aws_secret_access_key "${aws_iam_access_key.prom_user_access_key.secret}"
    aws configure set default.region "eu-west-2"

    # Step 2: Identify new servers
    new_servers=$(aws ec2 describe-instances --filters "Name=tag-key,Values=$projectname-*" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
    
    if [ -n "$new_servers" ]; then
        # Step 3: Create privateip.txt and list Private IPs
        echo "$new_servers" | sed "s/\b\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}\b/&:$target_port/" > "$private_ip_file"
        
        # Step 4: Locate prometheus server
        prometheus_ip=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$prometheus_server_tag" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
        
        if [ -n "$prometheus_ip" ]; then
            # Step 5: SSH into prometheus server
            scp -i "$SSH_KEY_PATH" "$private_ip_file" ubuntu@$prometheus_ip:/tmp/
            ssh -i "$SSH_KEY_PATH" ubuntu@$prometheus_ip << EOF
                # Step 6: Update prometheus.yml dynamically
                sed -i "/- targets:/s/\]$/,$(echo -n "['"; cat $private_ip_file | tr '\n' ',' | sed 's/,$//' | sed "s/$/:$target_port', /")]/" "$prometheus_config"
                sudo systemctl daemon-reload
                sudo systemctl restart prometheus
EOF
    fi
fi