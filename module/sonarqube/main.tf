resource "aws_instance" "sonarqube_server" {
  ami                         = var.ami
  instance_type               = "t2.medium"
  key_name                    = var.keypair
  vpc_security_group_ids      = [var.sonarqube-sg]
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  user_data                   = local.sonarqube_user_data
  tags = {
    Name = var.name
  }
}

# Create a new load balancer
resource "aws_elb" "elb-sonar" {
  name            = "elb-sonar"
  subnets         = var.elb-subnets
  security_groups = [var.sonarqube-sg]
  listener {
    instance_port      = 9000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = var.cert-arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:9000"
    interval            = 30
  }

  instances                   = [aws_instance.sonarqube_server.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "sonar-elb"
  }
}



#Delete S3 Bucket & Dynamo DB table (Delete Dynamo DB table first)
# aws s3 rb s3://tfstate-tspadp --force
# aws dynamodb delete-table --table-name tspadp-backend --region eu-west-2

#CLI command that would create s3 bucket and Dynamo db
#!/bin/bash
# aws s3api create-bucket --bucket tfstate-tspadp --region eu-west-2 --create-bucket-configuration LocationConstraint=your-region
# echo "bucket created"
# aws dynamodb create-table --table-name your table name --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST \
#     --region your region
# echo "dynamo DB created"

# create_bucket.sh