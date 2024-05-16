resource "aws_launch_template" "lt-prod" {
  name                   = "lt-prod"
  image_id               = var.ami-prod
  instance_type          = "t2.medium"
  key_name               = var.keyname
  vpc_security_group_ids = [var.asg-sg]
  user_data = base64encode(templatefile("../module/prod-asg/docker-script.sh", {
    nexus-ip             = var.nexus-ip-prd
  }))
  tags = {
    Name = "lt-prod"
  }
}

# Create an Auto Scaling Group (ASG) for the production environment
resource "aws_autoscaling_group" "asg-prd" {
  name                      = var.asg-prod-name
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 1
  force_delete              = true
  vpc_zone_identifier       = var.vpc-zone-id-prd
  target_group_arns         = [var.tg-arn]
  launch_template {
    id = aws_launch_template.lt-prod.id
  }
  tag {
    key                 = "Name"
    value               = var.asg-prod-name
    propagate_at_launch = true
  }
}