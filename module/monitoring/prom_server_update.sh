#!/bin/bash

projectname="jenkins-ansible-auto-discovery"
prometheus_server_tag="$projectname-promgraf"
private_ip_file="privateip.txt"
prometheus_config="/etc/prometheus/prometheus.yml"
target_port="9100"
sleep_duration=60
SSH_KEY_PATH="~/.ssh/id_rsa"

while true; do
    # Step 1: AWS CLI login
    aws configure set aws_access_key_id YOUR_ACCESS_KEY_ID
    aws configure set aws_secret_access_key YOUR_SECRET_ACCESS_KEY
    aws configure set default.region YOUR_REGION

    # Step 2: Identify new servers
    new_servers=$(aws ec2 describe-instances --filters "Name=tag-key,Values=$projectname-*" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
    
    if [ -n "$new_servers" ]; then
        # Step 3: Create privateip.txt and list Private IPs
        echo "$new_servers" | sed "s/\b\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}\b/&:$target_port/" > "$private_ip_file"
        
        # Step 4: Locate prometheus server
        prometheus_ip=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$prometheus_server_tag" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
        
        if [ -n "$prometheus_ip" ]; then
            # Step 5: SSH into prometheus server
            scp -i $SSH_KEY_PATH "$private_ip_file" ubuntu@$prometheus_ip:/tmp/
            ssh -i $SSH_KEY_PATH ubuntu@$prometheus_ip << EOF
                # Step 6: Copy private IP list
                scp user@local_machine:"$private_ip_file" /tmp/
                
                # Step 7: Update prometheus.yml dynamically
                sed -i '/- targets:/r /tmp/privateip.txt' "$prometheus_config"
                systemctl restart prometheus
EOF
        fi
    fi
    
    # Step 8: Wait for 60 seconds before looping
    sleep $sleep_duration
done