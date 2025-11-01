output "client-role-name" {
  value = aws_iam_role.k8s-client-role.name
}

output "subnet-ids" {
  value = var.use_existing_vpc ? var.existing_private_eks_subnet_ids : aws_subnet.private-subnet-workers[*].id
}

output "security-group-id" {
  value = aws_eks_cluster.k8s-cluster.vpc_config[*].cluster_security_group_id
}

output "cluster-endpoint" {
  value = aws_eks_cluster.k8s-cluster.endpoint
}

output "cluster-name" {
  value = aws_eks_cluster.k8s-cluster.name
}

output "cluster-region" {
  value = data.aws_region.current.name
}

output "cluster-certificate-authority-data" {
  value = aws_eks_cluster.k8s-cluster.certificate_authority[0].data
}

output "eks-oidc-issuer-url" {
  value = aws_eks_cluster.k8s-cluster.identity[0].oidc[0].issuer
}

output "eks-oidc-provider-arn" {
  value = aws_iam_openid_connect_provider.eks_oidc_provider.arn
}

