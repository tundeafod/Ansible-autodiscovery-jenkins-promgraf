resource "aws_launch_template" "lt-stage" {
  name                   = "lt-stage"
  image_id               = var.ami-stage
  instance_type          = "t2.medium"
  key_name               = var.keyname
  vpc_security_group_ids = [var.asg-sg]
  user_data = base64encode(templatefile("../module/stage-asg/docker-script.sh", {
    nexus-ip             = var.nexus-ip-stage
  }))
  tags = {
    Name = "lt-stage"
  }
}

# Create an Auto Scaling Group (ASG) for the production environment
resource "aws_autoscaling_group" "asg-stage" {
  name                      = var.asg-stage-name
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 1
  force_delete              = true
  vpc_zone_identifier       = var.vpc-zone-id-stage
  target_group_arns         = [var.tg-arn]
  launch_template {
    id = aws_launch_template.lt-stage.id
  }
  tag {
    key                 = "Name"
    value               = var.asg-stage-name
    propagate_at_launch = true
  }
}