output "subnet-id" {
  value = var.use_existing_vpc ? var.existing_public_subnet_ids : aws_subnet.public[*].id
}

#In case of existing VPC configuration, nat gateway will not be created in this module, hence set to null
output "nat-gw-id" {
  value = var.use_existing_vpc ? null : aws_nat_gateway.nat[0].id
}

output "nat-gw-ip" {
  value = var.use_existing_vpc? var.existing_nat_gw_eip : aws_nat_gateway.nat[0].public_ip
}