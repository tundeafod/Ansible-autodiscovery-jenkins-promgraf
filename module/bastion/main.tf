resource "aws_instance" "bastion_server" {
  ami                         = var.ami_redhat
  instance_type               = "t2.medium"
  key_name                    = var.keyname
  vpc_security_group_ids      = [var.bastion-sg]
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  user_data                   = local.bastion_user_data
  tags = {
    Name = var.name
  }
}