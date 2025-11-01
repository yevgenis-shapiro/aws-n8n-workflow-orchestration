resource "aws_db_subnet_group" "db-subnet-group" {
  subnet_ids = var.use_existing_vpc ? var.existing_private_rds_subnet_ids : aws_subnet.database[*].id
}

resource "aws_subnet" "database" {
  count             = var.use_existing_vpc ? 0 : min(length(var.availability-zones), length(var.cidr-blocks))
  cidr_block        = var.cidr-blocks[count.index]
  vpc_id            = var.vpc-id
  availability_zone = var.availability-zones[count.index]

  tags = merge(var.tags, {
    "Name"        = "${var.environment-prefix}-databases"
    "subnet-role" = "database"
  })
}