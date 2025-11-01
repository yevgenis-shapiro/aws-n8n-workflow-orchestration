variable "environment-prefix" {
  type        = string
  description = "A prefix to be prepended to every resource name"
  default     = "itom"
}

variable "tags" {
  type        = map(string)
  description = "Tags to be attached to every resource"
  default     = {}
}

variable "eks-oidc-issuer" {
  type        = string
  description = "EKS OIDC issuer for EBS CSI role creation"
}

variable "oidc-provider" {
  type        = string
  description = "OIDC provider for EBS CSI role creation"
}

variable "k8s-cluster-name" {
  type        = string
  description = "Kubernetes/EKS cluster name"
}

variable "k8s-cluster-endpoint" {
  type        = string
  description = "Kubernetes/EKS cluster endpoint"
}

variable "k8s-cluster-ca-data" {
  type        = string
  description = "Kubernetes/EKS cluster certificate authority"
}

variable "bastion-public-ip" {
  type        = string
  description = "Public IP Address of bastion host"
}

variable "bastion-username" {
  type        = string
  description = "The username to be used to log into Bastion; only necessary for custom bastion-ami-id"
  default     = "ec2-user"
}

variable "ssh-private-key" {
  type        = string
  description = "Private key for bastion remote access through ssh"
}

variable "helm-version" {
  type        = string
  description = "Version of Helm installed"
}