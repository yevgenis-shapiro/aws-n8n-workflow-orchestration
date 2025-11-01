#
# Amazon Certificate Manager based certificate (public hosted zone)
#
resource "aws_acm_certificate" "certificate" {
  count             = local.is_public_zone_defined ? 1 : 0
  domain_name       = "${lower(var.environment-prefix)}.${lower(var.public-hosted-zone)}"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${lower(var.environment-prefix)}.${lower(var.public-hosted-zone)}"
  ]
  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert-validation" {
  count = local.is_public_zone_defined ? 1 : 0

  allow_overwrite = true
  name            = aws_acm_certificate.certificate[0].domain_validation_options.*.resource_record_name[0]
  records         = [aws_acm_certificate.certificate[0].domain_validation_options.*.resource_record_value[0]]
  type            = aws_acm_certificate.certificate[0].domain_validation_options.*.resource_record_type[0]
  zone_id         = data.aws_route53_zone.parent-zone[0].zone_id
  ttl             = 60
}

#
# Self-signed CA/server certificate (private hosted zone)
#
resource "tls_private_key" "self-signed-ca-cert-key" {
  count = local.is_public_zone_defined ? 0 : 1

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "self-signed-ca-cert" {
  count = local.is_public_zone_defined ? 0 : 1

  allowed_uses          = ["cert_signing"]
  private_key_pem       = tls_private_key.self-signed-ca-cert-key[0].private_key_pem
  validity_period_hours = 24 * 365 * 2
  is_ca_certificate     = true

  subject {
    common_name = "${aws_route53_zone.private-zone.name}-ca-cert"
  }
}

resource "tls_private_key" "self-signed-cert-key" {
  count = local.is_public_zone_defined ? 0 : 1

  algorithm   = "RSA"
  rsa_bits    = "2048"
}

resource "tls_cert_request" "self-signed-cert-req" {
  count = local.is_public_zone_defined ? 0 : 1

  private_key_pem = tls_private_key.self-signed-cert-key[0].private_key_pem
  dns_names       = [aws_route53_zone.private-zone.name, "*.${aws_route53_zone.private-zone.name}"]

  subject {
    common_name = aws_route53_zone.private-zone.name
  }
}

resource "tls_locally_signed_cert" "self-signed-cert" {
  count = local.is_public_zone_defined ? 0 : 1

  allowed_uses          = ["server_auth"]
  validity_period_hours = 24 * 365 * 2

  ca_cert_pem        = tls_self_signed_cert.self-signed-ca-cert[0].cert_pem
  ca_private_key_pem = tls_private_key.self-signed-ca-cert-key[0].private_key_pem
  cert_request_pem   = tls_cert_request.self-signed-cert-req[0].cert_request_pem
}

resource "aws_acm_certificate" "self-signed-cert" {
  count = local.is_public_zone_defined ? 0 : 1

  private_key       = tls_private_key.self-signed-cert-key[0].private_key_pem
  certificate_body  = tls_locally_signed_cert.self-signed-cert[0].cert_pem
  certificate_chain = tls_self_signed_cert.self-signed-ca-cert[0].cert_pem
}

resource "local_file" "self-signed-ca-cert-key" {
  count = local.is_public_zone_defined ? 0 : 1

  content         = tls_private_key.self-signed-cert-key[0].private_key_pem
  filename        = "${var.environment-prefix}-lb-ca-cert.key"
  file_permission = "0600"
}

resource "local_file" "self-signed-ca-cert" {
  count = local.is_public_zone_defined ? 0 : 1

  content         = tls_self_signed_cert.self-signed-ca-cert[0].cert_pem
  filename        = "${var.environment-prefix}-lb-ca-cert.pem"
  file_permission = "0600"
}

resource "local_file" "self-signed-cert-key" {
  count = local.is_public_zone_defined ? 0 : 1

  content         = tls_private_key.self-signed-cert-key[0].private_key_pem
  filename        = "${var.environment-prefix}-lb-cert.key"
  file_permission = "0600"
}

resource "local_file" "self-signed-cert" {
  count = local.is_public_zone_defined ? 0 : 1

  content         = tls_locally_signed_cert.self-signed-cert[0].cert_pem
  filename        = "${var.environment-prefix}-lb-cert.pem"
  file_permission = "0600"
}
