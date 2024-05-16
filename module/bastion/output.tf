output "bastion_ip" {
  value = aws_instance.bastion_server.public_ip
}

output "bastion_id" {
  value = aws_instance.bastion_server.id
}