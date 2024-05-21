output "Sonarqube-ip" {
  value = module.sonarqube.sonarqube_ip
}

output "bastion-ip" {
  value = module.bastion.bastion_ip
}
output "jenkins_ip" {
  value = module.jenkins.jenkins_ip
}
output "ansible_ip" {
  value = module.ansible.ansible_ip
}

output "promgraf_ip" {
  value = module.monitoring.promgraf_ip
}

output "rds-endpoint" {
  value = module.database.rds-endpoint
}

output "nexus_pub_ip" {
  value = module.nexus.nexus_pub_ip
}

