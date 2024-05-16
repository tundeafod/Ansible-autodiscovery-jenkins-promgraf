output "jenkins_ip" {
  value = aws_instance.jenkins_server.private_ip
}
output "jenkins_id" {
  value = aws_instance.jenkins_server.id
}

output "jenkins_dns_name" {
  value = aws_elb.jenkins_lb.dns_name
}

output "jenkins_zone_id" {
  value = aws_elb.jenkins_lb.zone_id
}