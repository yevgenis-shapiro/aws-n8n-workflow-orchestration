data "aws_subnet" "public-subnet" {
  id = var.subnet-id
}

resource "aws_eip" "bastion_ip" {
  instance = aws_instance.bastion.id
  vpc      = true
  tags = merge(var.tags, {
    "Role" = "bastion"
    "Name" = "${var.environment-prefix}-bastion-ip"
  })
}

resource "aws_instance" "bastion" {
  ami           = (var.bastion-ami-id != "") ? var.bastion-ami-id : local.ami-id
  instance_type = "t3.medium"

  availability_zone      = data.aws_subnet.public-subnet.availability_zone
  subnet_id              = var.subnet-id
  vpc_security_group_ids = [aws_security_group.bastion.id]

  iam_instance_profile = aws_iam_instance_profile.bastion-instance-profile.name
  key_name             = var.ssh-key-pair-name
  ebs_optimized        = true
  
  root_block_device {
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.tags, {
    "Role" = "bastion"
    "Name" = "${var.environment-prefix}-bastion"
    "Deployment-ID" = var.deployment-id
  })
}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_vpc" "current_vpc"{
  id = var.vpc-id
}

resource "aws_iam_policy" "bastion-policy-one" {
  name   = "${var.environment-prefix}-bastion-policy-one"
  policy = templatefile("${path.module}/bastion-permissions-one.tpl",
  {
    eks-cluster-filter  = "arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.eks-cluster-name}",
    eks-nodegroup-filter  = "arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:nodegroup/${var.eks-cluster-name}/*",
    eks-addon-filter  = "arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:addon/${var.eks-cluster-name}/*",
    eks-identity-provider-config-filter  = "arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:identityproviderconfig/${var.eks-cluster-name}/*",
    efs-filter = var.efs-arn,
    rds-filter = join(",", var.rds-arns),
    ecr-filter =  "arn:${data.aws_partition.current.partition}:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/*"
  })
}

resource "aws_iam_policy" "bastion-policy-two" {
  name   = "${var.environment-prefix}-bastion-policy-two"
  policy = templatefile("${path.module}/bastion-permissions-two.tpl",
  {
    hostedzone-filter = trimsuffix(join(",", tolist([(var.private-hosted-zone-id == "") ? "" : "arn:${data.aws_partition.current.partition}:route53:::hostedzone/${var.private-hosted-zone-id}",
      (var.public-hosted-zone-id == "") ? "" : "arn:${data.aws_partition.current.partition}:route53:::hostedzone/${var.public-hosted-zone-id}"])), ","),
    deployment-id = var.deployment-id,
    vpc-filter = data.aws_vpc.current_vpc.arn
    certificate-arn = var.certificate-arn
  })
}

resource "aws_iam_role_policy_attachment" "bastion-role-bastion-policy-one" {
  policy_arn = aws_iam_policy.bastion-policy-one.arn
  role       = var.k8s-access-role-name
}

resource "aws_iam_role_policy_attachment" "bastion-role-bastion-policy-two" {
  policy_arn = aws_iam_policy.bastion-policy-two.arn
  role       = var.k8s-access-role-name
}

resource "aws_iam_role_policy_attachment" "bastion-role-dns-update-policy" {
  policy_arn = var.dns-update-policy-arn
  role       = var.k8s-access-role-name
}

resource "aws_iam_instance_profile" "bastion-instance-profile" {
  name = "${var.environment-prefix}-bastion-instance-profile"
  role = var.k8s-access-role-name

  depends_on = [ aws_iam_policy.bastion-policy-one, aws_iam_policy.bastion-policy-two ]
}

resource "aws_security_group" "bastion" {
  name   = "${var.environment-prefix}-bastion"
  vpc_id = data.aws_subnet.public-subnet.vpc_id

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = var.allowed-client-cidrs
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment-prefix}-bastion"
  })
}

data "aws_route53_zone" "parent-zone" {
  count   = length(var.dns-zone-ids)
  zone_id = var.dns-zone-ids[count.index]
}

resource "aws_route53_record" "bastion" {
  count   = length(data.aws_route53_zone.parent-zone)
  name    = "bastion.${data.aws_route53_zone.parent-zone[count.index].name}"
  type    = "A"
  zone_id = data.aws_route53_zone.parent-zone[count.index].zone_id
  ttl     = "300"
  records = [aws_eip.bastion_ip.public_ip]
}
