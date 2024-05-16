output "bastion_sg" {
  value = aws_security_group.bastion_sg.id
}

output "sonarqube_sg" {
  value = aws_security_group.sonarqube_sg.id
}

output "ansible_sg" {
  value = aws_security_group.ansible_sg.id
}

output "nexus_sg" {
  value = aws_security_group.nexus_sg.id
}

output "jenkins_sg" {
  value = aws_security_group.jenkins_sg.id
}

output "rds-sg" {
  value = aws_security_group.rds-sg.id
}

output "asg_sg" {
  value = aws_security_group.asg_sg.id
}

output "promgraf_sg" {
  value = aws_security_group.promgraf_sg.id
}