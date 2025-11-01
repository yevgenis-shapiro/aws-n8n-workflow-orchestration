resource "aws_subnet" "public" {
  count             = var.use_existing_vpc? 0 : min(length(var.availability-zones), length(var.cidr-blocks))
  vpc_id            = var.vpc-id
  cidr_block        = var.cidr-blocks[count.index]
  availability_zone = var.availability-zones[count.index]

  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.environment-prefix}-public-subnet-${count.index}"
  })
}

resource "aws_internet_gateway" "internet" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = var.vpc-id

  tags = merge(var.tags, {
    Name = "${var.environment-prefix}-internet-gw"
  })
}

resource "aws_route_table" "external-traffic" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = var.vpc-id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet[0].id
  }

  tags = var.tags
}

resource "aws_route_table_association" "public-subnet-to-internet" {
  count          = var.use_existing_vpc ? 0 : min(length(var.availability-zones), length(var.cidr-blocks))

  route_table_id = aws_route_table.external-traffic[0].id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_nat_gateway" "nat" {
  count         = var.use_existing_vpc ? 0 : 1
  allocation_id = aws_eip.nat-gw-ip[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name = "${var.environment-prefix}-nat-gw"
  })
}

resource "aws_eip" "nat-gw-ip" {
  count = var.use_existing_vpc ? 0 : 1
  vpc = true

  tags = merge(var.tags, {
    Name = "${var.environment-prefix}-nat-gw-ip"
    "eip-role" = "nat-gw-ip"
  })
}
//
//resource "aws_acm_certificate" "certificate" {
//  domain_name       = "${lower(var.environment-prefix)}.${lower(var.domain)}"
//  validation_method = "DNS"
//
//  tags = var.tags
//
//  lifecycle {
//    create_before_destroy = true
//  }
//}
//
//data "aws_route53_zone" "domain" {
//  name         = var.domain
//  private_zone = false
//}
//
//resource "aws_route53_record" "cert-validation" {
//  allow_overwrite = true
//  name            = aws_acm_certificate.certificate.domain_validation_options.*.resource_record_name[0]
//  records         = [aws_acm_certificate.certificate.domain_validation_options.*.resource_record_value[0]]
//  type            = aws_acm_certificate.certificate.domain_validation_options.*.resource_record_type[0]
//  zone_id         = data.aws_route53_zone.domain.zone_id
//  ttl             = 60
//}
