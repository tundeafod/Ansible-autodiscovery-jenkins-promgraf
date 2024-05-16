# Create prometheus & grafana Server

resource "aws_instance" "promgraf-server" {
  ami                         = var.ami
  instance_type               = "t2.medium"
  key_name                    = var.keypair
  vpc_security_group_ids      = [var.promgraf-sg]
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  user_data                   = local.monitoring-script
  tags = {
    Name = var.name
  }
}

resource "aws_elb" "prom" {
  name            = "elb-prom"
  subnets         = var.elb-subnets
  security_groups = [var.promgraf-sg]
  listener {
    instance_port      = 9090
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = var.cert-arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:9090"
    interval            = 30
  }


  instances                   = [aws_instance.promgraf-server.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "prom-elb"
  }
}

resource "aws_elb" "graf" {
  name            = "elb-graf"
  subnets         = var.elb-subnets
  security_groups = [var.promgraf-sg]
  listener {
    instance_port      = 3000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = var.cert-arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:3000"
    interval            = 30
  }


  instances                   = [aws_instance.promgraf-server.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "graf-elb"
  }
}

resource "aws_elb" "nodeexporter" {
  name            = "elb-nodeexporter"
  subnets         = var.elb-subnets
  security_groups = [var.promgraf-sg]
  listener {
    instance_port      = 9100
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = var.cert-arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:9100"
    interval            = 30
  }


  instances                   = [aws_instance.promgraf-server.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "nodeexporter-elb"
  }
}