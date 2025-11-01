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

variable "subnet-id" {
  type        = string
  description = "ID of the subnet that bastion VM will connect to"
}

variable "ssh-key-pair-name" {
  type        = string
  description = "Name of an SSH key pair to use for login to bastion VM"
}

variable "ssh-private-key" {
  type        = string
  description = "Private key to use for login to bastion VM"
}

variable "k8s-access-role-name" {
  type        = string
  description = "Client role that has access rights to K8S cluster"
}

variable "dns-zone-ids" {
  type        = list(string)
  description = "DNS hosted zones to which to add an A record for bastion VM"
}

variable "dns-update-policy-arn" {
  type        = string
  description = "Role that give Bastion permission to update DNS records (for Load Balancer addresses)"
}

variable "allowed-client-cidrs" {
  type        = list(string)
  description = "Limit the IP address ranges that are allowed to access bastion"
}

variable "eks-cluster-name" {
  type        = string
  description = "EKS cluster name for providing specific EKS permissions to bastion host"
}

variable "efs-arn" {
  type        = string
  description = "EFS Arn for providing specific EFS permissions to bastion host"
}

variable "rds-arns" {
  type        = list(string)
  description = "List of RDS ARNs providing specific RDS permissions to bastion host"
}

variable "private-hosted-zone-id" {
  type        = string
  description = "Route 53 Private Hosted Zone ID providing specific Route53 permissions to bastion host"
}

variable "public-hosted-zone-id" {
  type        = string
  description = "Route 53 Public Hosted Zone ID providing specific Route53 permissions to bastion host"
}

variable "vpc-id" {
  type        = string
  description = "AWS VPC ID"
}

variable "deployment-id" {
  type        = string
  description = "A unique id that will be attached as a tag to EC2 instance. The unique id value will be used for condition for Bastion's IAM Policy"
}

variable "certificate-arn" {
  type        = string
  description = "ARN of the certificate used for external communication"
}

variable "bastion-ami-id" {
  type        = string
  description = "The AMI to use for bastion; change with care, several scripts need to run on the machine"
  default     = ""
}
