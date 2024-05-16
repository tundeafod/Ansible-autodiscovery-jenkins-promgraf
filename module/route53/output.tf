output "jenkins_record" {
  value = aws_route53_record.jenkins_record.id
}

output "prom_record" {
  value = aws_route53_record.prom_record.id
}

output "graf_record" {
  value = aws_route53_record.graf_record.id
}

output "nexus_record" {
  value = aws_route53_record.nexus_record.id
}

output "sonarqube_record" {
  value = aws_route53_record.sonarqube_record.id
}

output "prod_record" {
  value = aws_route53_record.prod_record.id
}

output "stage_record" {
  value = aws_route53_record.stage_record.id
}

output "zone_id" {
  value = data.aws_route53_zone.route53_zone.zone_id
}