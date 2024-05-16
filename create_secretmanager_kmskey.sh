#!/bin/bash

# Create a KMS key for RDS and save its Key ID to a file
aws kms create-key --description "KMS key for RDS" --query 'KeyMetadata.KeyId' --output text > kms_key_id.txt

# Create a random password
random_password=$(openssl rand -base64 12 | tr -d '/@\"[:space:]')

# Create a secret in AWS Secrets Manager with the random password
aws secretsmanager create-secret --name afodsecret --description "My secret" --secret-string "$random_password"

# Retrieve the ARN of the KMS key used by AWS Secrets Manager
KMS_KEY_ARN=$(aws kms describe-key --key-id alias/aws/secretsmanager --query 'KeyMetadata.Arn' --output text)

# Update the secret to use the KMS key
aws secretsmanager update-secret --secret-id afodsecret --kms-key-id $KMS_KEY_ARN --secret-string "$random_password"

# Confirmation message
echo "KMS/Secretmanager create"
