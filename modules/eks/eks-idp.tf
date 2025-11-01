/*data "tls_certificate" "eks_oidc_issuer_certificate" {
  url = aws_eks_cluster.k8s-cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  url = aws_eks_cluster.k8s-cluster.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc_issuer_certificate.certificates.0.sha1_fingerprint]
}*/

//TODO - go back to original code commented above once we fix the certificate read issues on CentOS systems.
resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  url = aws_eks_cluster.k8s-cluster.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
}