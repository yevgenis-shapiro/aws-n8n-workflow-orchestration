output "vpc-id" {
  value = var.use_existing_vpc ? var.existing_vpc_id : aws_vpc.main[0].id
}

output "vpc-cidr" {
  value = var.use_existing_vpc ? var.vpc-cidr-block : aws_vpc.main[0].cidr_block
}