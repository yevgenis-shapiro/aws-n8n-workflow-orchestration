output "public-ip" {
  value = aws_eip.bastion_ip.public_ip
}

output "fqdn" {
  value = aws_route53_record.bastion[*].fqdn
}

output "security-groups" {
  value = aws_security_group.bastion.id
}