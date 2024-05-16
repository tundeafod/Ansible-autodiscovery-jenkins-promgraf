output "promgraf_ip" {
  value = aws_instance.promgraf-server.public_ip
}

output "prom_dns_name" {
  value = aws_elb.prom.dns_name
}

output "prom_zone_id" {
  value = aws_elb.prom.zone_id
}

output "graf_dns_name" {
  value = aws_elb.graf.dns_name
}

output "graf_zone_id" {
  value = aws_elb.graf.zone_id
}

output "nodeexporter_dns_name" {
  value = aws_elb.nodeexporter.dns_name
}

output "nodeexporter_zone_id" {
  value = aws_elb.nodeexporter.zone_id
}