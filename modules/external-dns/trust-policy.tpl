{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${oidc-provider}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${eks-oidc-issuer}:sub": "system:serviceaccount:${k8s-namespace}:external-dns"
        }
      }
    }
  ]
}