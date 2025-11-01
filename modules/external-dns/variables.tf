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
  type = string
  description = "EKS OIDC issuer for EBS CSI role creation"
}

variable "oidc-provider" {
  type = string
  description = "OIDC provider for EBS CSI role creation"
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

variable "k8s-namespaces-for-external-dns" {
  type        = list(string)
  description = "List of Kubernetes namespaces where External DNS needs to be enabled."
}

variable "dns-domain-name" {
  type        = string
  description = "will make ExternalDNS see only the hosted zones matching provided domain"
  default     = ""
}

variable "limit-queries" {
  type        = bool
  description = "lower query interval and define cache to prevent route53 throttling)"
  default     = false
}
