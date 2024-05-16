locals {
  name = "TSPADP"
}

data "aws_secretsmanager_secret_version" "afodsecret" {
  secret_id = "afodsecret"
}

module "keypair" {
  source = "../module/keypair"
}

module "vpc" {
  source         = "../module/vpc"
  private-subnet = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  public-subnet  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  azs            = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

module "securitygroup" {
  source = "../module/securitygroup"
  vpc_id = module.vpc.vpc_id
}

module "sonarqube" {
  source       = "../module/sonarqube"
  ami          = "ami-053a617c6207ecc7b"
  sonarqube-sg = module.securitygroup.sonarqube_sg
  subnet_id    = module.vpc.publicsub1
  keypair      = module.keypair.public-key-id
  name         = "${local.name}-sonarqube"
  elb-subnets  = [module.vpc.publicsub1, module.vpc.publicsub2, module.vpc.publicsub3]
  cert-arn     = module.acm.acm_certificate
}

module "bastion" {
  source      = "../module/bastion"
  ami_redhat  = "ami-035cecbff25e0d91e"
  subnet_id   = module.vpc.publicsub2
  bastion-sg  = module.securitygroup.bastion_sg
  keyname     = module.keypair.public-key-id
  private_key = module.keypair.private-key-id
  name        = "${local.name}-bastion"
}
module "nexus" {
  source      = "../module/nexus"
  ami_redhat  = "ami-035cecbff25e0d91e"
  subnet_id   = module.vpc.publicsub3
  nexus-sg    = module.securitygroup.nexus_sg
  keyname     = module.keypair.public-key-id
  name        = "${local.name}-nexus"
  elb-subnets = [module.vpc.publicsub1, module.vpc.publicsub2, module.vpc.publicsub3]
  cert-arn    = module.acm.acm_certificate
}
module "jenkins" {
  source     = "../module/jenkins"
  ami-redhat = "ami-035cecbff25e0d91e"
  subnet-id  = module.vpc.privatesub1
  jenkins-sg = module.securitygroup.jenkins_sg
  key-name   = module.keypair.public-key-id
  name       = "${local.name}-jenkins"
  nexus-ip   = module.nexus.nexus_ip
  subnet-elb = [module.vpc.publicsub1, module.vpc.publicsub2, module.vpc.publicsub3]
  cert-arn   = module.acm.acm_certificate
}
module "ansible" {
  source      = "../module/ansible"
  ami-redhat  = "ami-035cecbff25e0d91e"
  subnet-id   = module.vpc.publicsub2
  ansible-sg  = module.securitygroup.ansible_sg
  key-name    = module.keypair.public-key-id
  name        = "${local.name}-ansible"
  nexus-ip    = module.nexus.nexus_ip
  private_key = module.keypair.private-key-id
}

module "database" {
  source                  = "../module/database"
  db_subnet_grp           = "db-subnetgroup"
  subnet                  = [module.vpc.privatesub1, module.vpc.privatesub2, module.vpc.privatesub3]
  security_group_mysql_sg = module.securitygroup.rds-sg
  db_name                 = "petclinic"
  db_username             = "admin"
  db_password             = data.aws_secretsmanager_secret_version.afodsecret.secret_string
  name                    = "${local.name}-db-subnet"
}

module "monitoring" {
  source       = "../module/monitoring"
  ami          = "ami-053a617c6207ecc7b"
  promgraf-sg  = module.securitygroup.promgraf_sg
  subnet_id    = module.vpc.publicsub1
  keypair      = module.keypair.public-key-id
  name         = "${local.name}-promgraf"
  nexus-ip     = module.nexus.nexus_ip
  jenkins_ip   = module.jenkins.jenkins_ip
  ansible_ip   = module.ansible.ansible_ip
  Sonarqube-ip = module.sonarqube.sonarqube_ip
  # prom_server_discovery-script = "${path.root}./module/monitoring/prom_server_update.sh"
  # private_key                  = module.keypair.private-key-id
  elb-subnets = [module.vpc.publicsub1, module.vpc.publicsub2, module.vpc.publicsub3]
  cert-arn    = module.acm.acm_certificate
}

module "prod-asg" {
  source          = "../module/prod-asg"
  ami-prod        = "ami-035cecbff25e0d91e"
  keyname         = module.keypair.public-key-id
  asg-sg          = module.securitygroup.asg_sg
  nexus-ip-prd    = module.nexus.nexus_ip
  vpc-zone-id-prd = [module.vpc.privatesub1, module.vpc.privatesub2, module.vpc.privatesub3]
  tg-arn          = module.prod-lb.prod-tg-arn
  asg-prod-name   = "${local.name}-prod-asg"
}

module "stage-asg" {
  source            = "../module/stage-asg"
  ami-stage         = "ami-035cecbff25e0d91e"
  asg-sg            = module.securitygroup.asg_sg
  keyname           = module.keypair.public-key-id
  nexus-ip-stage    = module.nexus.nexus_ip
  vpc-zone-id-stage = [module.vpc.privatesub1, module.vpc.privatesub2, module.vpc.privatesub3]
  tg-arn            = module.stage-lb.stage-tg-arn
  asg-stage-name    = "${local.name}-stage-asg"
}

module "prod-lb" {
  source          = "../module/prod-lb"
  vpc_id          = module.vpc.vpc_id
  prod-sg         = [module.securitygroup.asg_sg]
  prod-subnet     = [module.vpc.publicsub1, module.vpc.publicsub2, module.vpc.publicsub3]
  certificate_arn = module.acm.acm_certificate
  prod-alb-name   = "${local.name}-prod-alb"
}

module "stage-lb" {
  source          = "../module/stage-lb"
  vpc_id          = module.vpc.vpc_id
  stage-sg        = [module.securitygroup.asg_sg]
  stage-subnet    = [module.vpc.publicsub1, module.vpc.publicsub2, module.vpc.publicsub3]
  certificate_arn = module.acm.acm_certificate
  stage-alb-name  = "${local.name}-stage-alb"
}

module "acm" {
  source       = "../module/acm"
  domain_name  = "tundeafod.click"
  domain_name2 = "*.tundeafod.click"
}

module "route53" {
  source                = "../module/route53"
  domain-name           = "tundeafod.click"
  jenkins_domain_name   = "jenkins.tundeafod.click"
  jenkins_lb_dns_name   = module.jenkins.jenkins_dns_name
  jenkins_lb_zone_id    = module.jenkins.jenkins_zone_id
  nexus_domain_name     = "nexus.tundeafod.click"
  nexus_lb_dns_name     = module.nexus.nexus_dns_name
  nexus_lb_zone_id      = module.nexus.nexus_zone_id
  sonarqube_domain_name = "sonarqube.tundeafod.click"
  sonarqube_lb_dns_name = module.sonarqube.sonarqube_dns_name
  sonarqube_lb_zone_id  = module.sonarqube.sonarqube_zone_id
  prod_domain_name      = "prod.tundeafod.click"
  prod_lb_dns_name      = module.prod-lb.prod-lb-dns
  prod_lb_zone_id       = module.prod-lb.prod-lb-zoneid
  stage_domain_name     = "stage.tundeafod.click"
  stage_lb_dns_name     = module.stage-lb.stage-lb-dns
  stage_lb_zone_id      = module.stage-lb.stage-lb-zoneid
  prom_domain_name      = "prom.tundeafod.click"
  prom_lb_dns_name      = module.monitoring.prom_dns_name
  prom_lb_zone_id       = module.monitoring.prom_zone_id
  graf_domain_name      = "graf.tundeafod.click"
  graf_lb_dns_name      = module.monitoring.graf_dns_name
  graf_lb_zone_id       = module.monitoring.graf_zone_id
}
