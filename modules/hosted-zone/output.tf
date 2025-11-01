output "dns-zone-id" {
  value = local.is_public_zone_defined ? aws_route53_zone.public-zone[0].zone_id : aws_route53_zone.private-zone.zone_id
}

output "dns-domain-name" {
  value = local.is_public_zone_defined ? aws_route53_zone.public-zone[0].name : aws_route53_zone.private-zone.name
}

output "acm-certificate-arn" {
  value = local.is_public_zone_defined ? aws_acm_certificate.certificate[0].arn : aws_acm_certificate.self-signed-cert[0].arn
}

output "acm-self-signed-certificate-arn-data" {
  value = aws_acm_certificate.self-signed-cert[*].certificate_body
}

output "acm-self-signed-ca-certificate-arn-data" {
  value = aws_acm_certificate.self-signed-cert[*].certificate_chain
}

output "update-domain-policy-arn" {
  value = aws_iam_policy.update-domain-record.arn
}

output "dns-public-zone-id" {
  value = local.is_public_zone_defined ? aws_route53_zone.public-zone[0].id : ""
}

output "dns-private-zone-id" {
  value = aws_route53_zone.private-zone.zone_id
}