#!/bin/bash
aws s3 rb s3://tfstate-tspadp --force
echo "bucket deleted"

aws dynamodb delete-table --table-name tspadp-backend --region eu-west-3
echo "table deleted"