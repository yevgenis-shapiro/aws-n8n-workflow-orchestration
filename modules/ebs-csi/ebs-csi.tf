locals {
  eks-ebs-csi-driver-policy-name = "${var.environment-prefix}-AmazonEKS_EBS_CSI_Driver_Policy"
  eks-ebs-csi-driver-role = "${var.environment-prefix}-AmazonEKS_EBS_CSI_DriverRole"
}

resource "aws_iam_policy" "eks-ebs-csi-driver-policy" {
  name = local.eks-ebs-csi-driver-policy-name
  description = "IAM policy with permissions necessary to operate EKS EBS CSI driver."
  # Policy is located at https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/v0.9.0/docs/example-iam-policy.json
  # AWS CSI Reference - https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSnapshot",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:ModifyVolume",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:volume/*",
        "arn:aws:ec2:*:*:snapshot/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:CreateAction": [
            "CreateVolume",
            "CreateSnapshot"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteTags"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:volume/*",
        "arn:aws:ec2:*:*:snapshot/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/CSIVolumeName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/kubernetes.io/cluster/*": "owned"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/CSIVolumeName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/kubernetes.io/cluster/*": "owned"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/CSIVolumeSnapshotName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role" "eks-ebs-csi-driver-role" {
  name = local.eks-ebs-csi-driver-role
  description = "IAM role that allows the EKS EBS CSI driver's service account to make calls to AWS APIs on account owner's behalf"
  # AWS CSI Reference - https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html
  assume_role_policy = templatefile("${path.module}/trust-policy.tpl",
    {
      oidc-provider = var.oidc-provider,
      eks-oidc-issuer = replace(var.eks-oidc-issuer, "https://", "")
    }
  )
  tags = merge(var.tags, {
    Name = local.eks-ebs-csi-driver-role
  })
}

resource "aws_iam_role_policy_attachment" "eks-ebs-csi-driver-role-policy-attach" {
  role       = aws_iam_role.eks-ebs-csi-driver-role.name
  policy_arn = aws_iam_policy.eks-ebs-csi-driver-policy.arn
}

resource "null_resource" "setup-driver" {

  provisioner "remote-exec" {
    connection {
      host = var.bastion-public-ip
      type = "ssh"
      user = var.bastion-username
      timeout = "10m"
      private_key = var.ssh-private-key
      agent = false
    }
    inline = [
      "/usr/local/bin/helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver",
      "/usr/local/bin/helm repo update",
      "/usr/local/bin/helm upgrade --install --namespace kube-system --set enableVolumeScheduling=true --set enableVolumeResizing=true --set enableVolumeSnapshot=true --set serviceAccount.controller.annotations.\"eks\\.amazonaws\\.com/role-arn\"=${aws_iam_role.eks-ebs-csi-driver-role.arn} aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver --version ${var.csi-driver-helmchart-version}"
    ]
  }
}
