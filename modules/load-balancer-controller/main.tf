provider "kubernetes" {
  host                   = var.k8s-cluster-endpoint
  cluster_ca_certificate = base64decode(var.k8s-cluster-ca-data)
  //  token                  = data.aws_eks_cluster_auth.k8s-auth-data.token
  exec {
    api_version = "client.authentication.k8s.io/v1"
    args        = ["eks", "get-token", "--cluster-name", var.k8s-cluster-name]
    command     = "aws"
  }
}

resource "aws_iam_policy" "lbc-policy" {
  name   = "${var.environment-prefix}-load-balancer-controller"
  policy = file("${path.module}/lbc-policy.tpl")
}
resource "aws_iam_role" "load-balancer-controller-role" {
  name = "${var.environment-prefix}-load-balancer-controller-role"

  assume_role_policy = templatefile("${path.module}/trust-policy.tpl",
    {
      oidc-provider   = var.oidc-provider,
      eks-oidc-issuer = replace(var.eks-oidc-issuer, "https://", "")
    }
  )
  tags = merge(var.tags, {
    Name = "${var.environment-prefix}-load-balancer-controller-role"
  })
}

resource "aws_iam_role_policy_attachment" "lbc-policy-on-lbc-role" {
  policy_arn = aws_iam_policy.lbc-policy.arn
  role       = aws_iam_role.load-balancer-controller-role.name
}

resource "kubernetes_service_account" "lbc-service-account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    labels = {
      "app.kubernetes.io/component" = "controller",
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }

    annotations = {
      "eks.amazonaws.com/role-arn" : aws_iam_role.load-balancer-controller-role.arn
    }
  }
}

resource "null_resource" "lbc-chart" {
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
      "echo  ${var.helm-version}",
      "helm repo add eks https://aws.github.io/eks-charts",
      "helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller --set clusterName=${var.k8s-cluster-name} --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller -n kube-system | tee ~/system-setup/install_load_balancer_controller.log"
    ]
  }
}
