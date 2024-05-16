#!/bin/bash
aws secretsmanager delete-secret --secret-id afodsecret --force-delete-without-recovery

KMS_KEY_ID=$(cat kms_key_id.txt)
aws kms schedule-key-deletion --key-id $KMS_KEY_ID --pending-window-in-days 7

# Check if the key deletion is pending
DELETION_STATUS=$(aws kms describe-key --key-id $KMS_KEY_ID --query 'KeyMetadata.KeyState' --output text)

if [ "$DELETION_STATUS" = "PendingDeletion" ]; then
    echo "Key deletion is pending. Proceeding with cancellation..."
    aws kms cancel-key-deletion --key-id $KMS_KEY_ID
else
    echo "Key deletion is not pending. No need to cancel."
fi

# Describe the key to check its status
aws kms describe-key --key-id $KMS_KEY_ID
echo "Key described"

# Delete the key if it's not in PendingDeletion state
if [ "$DELETION_STATUS" != "PendingDeletion" ]; then
    aws kms delete-key --key-id $KMS_KEY_ID    
fi
echo "Key deletion completed"
