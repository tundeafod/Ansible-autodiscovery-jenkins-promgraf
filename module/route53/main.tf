# Route 53 hosted zone
data "aws_route53_zone" "route53_zone" {
  name         = var.domain-name
  private_zone = false
}

# Create A Route 53 record
resource "aws_route53_record" "jenkins_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = var.jenkins_domain_name
  type    = "A"
  alias {
    name                   = var.jenkins_lb_dns_name
    zone_id                = var.jenkins_lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "prom_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = var.prom_domain_name
  type    = "A"
  alias {
    name                   = var.prom_lb_dns_name
    zone_id                = var.prom_lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "graf_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = var.graf_domain_name
  type    = "A"
  alias {
    name                   = var.graf_lb_dns_name
    zone_id                = var.graf_lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "nexus_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = var.nexus_domain_name
  type    = "A"
  alias {
    name                   = var.nexus_lb_dns_name
    zone_id                = var.nexus_lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "sonarqube_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = var.sonarqube_domain_name
  type    = "A"
  alias {
    name                   = var.sonarqube_lb_dns_name
    zone_id                = var.sonarqube_lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "prod_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = var.prod_domain_name
  type    = "A"
  alias {
    name                   = var.prod_lb_dns_name
    zone_id                = var.prod_lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "stage_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = var.stage_domain_name
  type    = "A"
  alias {
    name                   = var.stage_lb_dns_name
    zone_id                = var.stage_lb_zone_id
    evaluate_target_health = true
  }
}