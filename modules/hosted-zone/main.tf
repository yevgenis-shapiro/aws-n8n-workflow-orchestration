locals {
  is_public_zone_defined = length(var.public-hosted-zone) > 0
}

data "aws_route53_zone" "parent-zone" {
  count = local.is_public_zone_defined ? 1 : 0
  name  = var.public-hosted-zone
}

resource "aws_route53_zone" "public-zone" {
  count = local.is_public_zone_defined ? 1 : 0

  name = "${var.environment-prefix}.${var.public-hosted-zone}"

  tags = var.tags
}

resource "aws_route53_record" "public-zone-ns-entries" {
  count = local.is_public_zone_defined ? 1 : 0

  name    = "${var.environment-prefix}.${var.public-hosted-zone}"
  type    = "NS"
  zone_id = data.aws_route53_zone.parent-zone[0].zone_id
  ttl     = 300
  records = aws_route53_zone.public-zone[0].name_servers
}

resource "aws_route53_zone" "private-zone" {
  name = "${var.environment-prefix}.${var.private-hosted-zone}"

  vpc {
    vpc_id = var.vpc-ic
  }

  tags = var.tags
}

resource "aws_iam_policy" "update-domain-record" {
  name = "${var.environment-prefix}-update-domain-record"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:GetHostedZone",
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/${local.is_public_zone_defined ? aws_route53_zone.public-zone[0].id : aws_route53_zone.private-zone.id}"
      }
    ]
  })
}