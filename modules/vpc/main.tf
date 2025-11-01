resource "aws_vpc" "main" {
  count      = var.use_existing_vpc ? 0 : 1
  cidr_block = var.vpc-cidr-block

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.environment-prefix}-vpc"
  })
}