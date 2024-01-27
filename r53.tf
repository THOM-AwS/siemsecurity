# Hosted Zone - Reference an existing hosted zone
resource "aws_route53_zone" "apse2-name" {
  name = "apse2.com"
}

# ACM Certificate for the domain
resource "aws_acm_certificate" "apse2_wildcard_cert" {
  domain_name       = "*.apse2.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "apse2WildcardCert"
  }
}


# DNS record for ACM validation
resource "aws_route53_record" "apse2_wildcard_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.apse2_wildcard_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  name    = each.value.name
  type    = each.value.type
  zone_id = aws_route53_zone.apse2.zone_id
  records = [each.value.record]
  ttl     = 60
}

# ACM Certificate validation
resource "aws_acm_certificate_validation" "apse2_wildcard_cert_validation" {
  certificate_arn         = aws_acm_certificate.apse2_wildcard_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.apse2_wildcard_cert_validation : record.fqdn]
}
