locals {
  external-dns-policy-name = "${var.environment-prefix}-AmazonEKS_EXTERNAL_DNS_Policy"
  external-dns-role        = "${var.environment-prefix}-AmazonEKS_EXTERNAL_DNS_ROLE"
}

resource "aws_iam_policy" "eks-external-dns-policy" {
  count       = length(var.k8s-namespaces-for-external-dns) > 0 ? 1 : 0
  name        = local.external-dns-policy-name
  description = "IAM policy with permissions necessary to operate external dns"
  # Instructions can be found at - https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role" "eks-external-dns-role" {
  count       = length(var.k8s-namespaces-for-external-dns)
  name        = "${local.external-dns-role}-${var.k8s-namespaces-for-external-dns[count.index]}"
  description = "IAM role that allows the external-dns service account to make calls to AWS APIs on account owner's behalf"
  assume_role_policy = templatefile("${path.module}/trust-policy.tpl",
    {
      oidc-provider   = var.oidc-provider,
      eks-oidc-issuer = replace(var.eks-oidc-issuer, "https://", "")
      k8s-namespace   = var.k8s-namespaces-for-external-dns[count.index]
    }
  )
  tags = merge(var.tags, {
    Name = "${local.external-dns-role}-${var.k8s-namespaces-for-external-dns[count.index]}"
  })
}

resource "aws_iam_role_policy_attachment" "eks-external-dns-role-policy-attach" {
  count      = length(var.k8s-namespaces-for-external-dns)
  role       = aws_iam_role.eks-external-dns-role[count.index].name
  policy_arn = aws_iam_policy.eks-external-dns-policy[0].arn
}

resource "null_resource" "setup-external-dns" {

  count = length(var.k8s-namespaces-for-external-dns)

  provisioner "file" {
    content = templatefile("${path.module}/kubernetes-manifest.tpl",
      {
        iam-role-arn    = aws_iam_role.eks-external-dns-role[count.index].arn,
        k8s-namespace   = var.k8s-namespaces-for-external-dns[count.index],
        dns-domain-name = var.dns-domain-name,
        limit-queries   = var.limit-queries
    })
    destination = "/home/${var.bastion-username}/system-setup/external-dns-${var.k8s-namespaces-for-external-dns[count.index]}.yaml"

    connection {
      host        = var.bastion-public-ip
      type        = "ssh"
      user        = var.bastion-username
      timeout     = "10m"
      private_key = var.ssh-private-key
      agent       = false
    }
  }

  provisioner "remote-exec" {
    connection {
      host        = var.bastion-public-ip
      type        = "ssh"
      user        = var.bastion-username
      timeout     = "10m"
      private_key = var.ssh-private-key
      agent       = false
    }
    inline = [
      "kubectl create ns ${var.k8s-namespaces-for-external-dns[count.index]}",
      "kubectl create -f ~/system-setup/external-dns-${var.k8s-namespaces-for-external-dns[count.index]}.yaml -n ${var.k8s-namespaces-for-external-dns[count.index]}"
    ]
  }
}
