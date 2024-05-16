output "nexus_ip" {
  value = aws_instance.nexus_server.public_ip
}
output "nexus_id" {
  value = aws_instance.nexus_server.id
}
output "nexus_dns_name" {
  value = aws_elb.elb-nexus.dns_name
}
output "nexus_zone_id" {
  value = aws_elb.elb-nexus.zone_id
}
