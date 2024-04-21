# Hosted Zone - Reference an existing hosted zone
data "aws_route53_zone" "_127cyber-name" {
  zone_id = "Z03093112GERZ97ION6VA"
}

# ACM Certificate for the domain
resource "aws_acm_certificate" "_127cyber_wildcard_cert" {
  domain_name       = "*.127cyber.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "127cyberWildcardCert"
  }
}


# DNS record for ACM validation
resource "aws_route53_record" "_127cyber_wildcard_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate._127cyber_wildcard_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  name    = each.value.name
  type    = each.value.type
  zone_id = data.aws_route53_zone._127cyber-name.zone_id
  records = [each.value.record]
  ttl     = 60
}

# ACM Certificate validation
resource "aws_acm_certificate_validation" "_127cyber_wildcard_cert_validation" {
  certificate_arn         = aws_acm_certificate._127cyber_wildcard_cert.arn
  validation_record_fqdns = [for record in aws_route53_record._127cyber_wildcard_cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}


resource "aws_route53_record" "wazuh_record" {
  zone_id = data.aws_route53_zone._127cyber-name.zone_id
  name    = "wazuh.127cyber.com"
  type    = "A"

  alias {
    name                   = aws_lb.soc_alb.dns_name
    zone_id                = aws_lb.soc_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "grafana_record" {
  zone_id = data.aws_route53_zone._127cyber-name.zone_id
  name    = "dashboards.127cyber.com"
  type    = "A"

  alias {
    name                   = aws_lb.soc_alb.dns_name
    zone_id                = aws_lb.soc_alb.zone_id
    evaluate_target_health = true
  }
}

# resource "aws_route53_record" "graylog_record" {
#   zone_id = aws_route53_zone._127cyber-name.zone_id
#   name    = "graylog.127cyber.com"
#   type    = "A"

#   alias {
#     name                   = aws_lb.soc_alb.dns_name
#     zone_id                = aws_lb.soc_alb.zone_id
#     evaluate_target_health = true
#   }
# }

# DNS Record in Route 53 for the NLB
# resource "aws_route53_record" "nlb_dns" {
#   zone_id = data.aws_route53_zone._127cyber-name.zone_id
#   name    = "listen.127cyber.com"
#   type    = "CNAME"
#   ttl     = "300"
#   records = [aws_lb.nlb_wazuh.dns_name]
# }
