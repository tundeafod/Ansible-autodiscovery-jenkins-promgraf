output "ansible_ip" {
  value = aws_instance.ansible_server.public_ip
}
output "ansible_id" {
  value = aws_instance.ansible_server.id
}