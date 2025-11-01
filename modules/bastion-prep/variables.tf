variable "bastion-public-ip" {
  type        = string
  description = "Public IP Address of bastion host"
}

variable "ssh-private-key" {
  type        = string
  description = "Private key for bastion remote access through ssh"
}

#kubectl related parameters

variable "kubectl_download_location" {
  type        = string
  description = "Download location for Kubernetes client"
}

variable "eks_cluster_region" {
  type        = string
  description = "Region for EKS cluster"
}

variable "eks_cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "database-engine" {
  type        = string
  description = "Database engine. Supported: postgres and oracle-ee"
}

variable "database-engine-version" {
  type        = string
  description = "Database engine version."
}

#efs mount related

variable "efs_dns" {
  type        = string
  description = "efs dns name for bastion"
}


variable "uid" {
  type        = string
  description = "UID"
  default     = "1999"
}

variable "gid" {
  type        = string
  description = "GID"
  default     = "1999"
}

#ITOM Software

variable "itom-software-directory" {
  type        = string
  description = "Directory that container various ITOM Software binaries such as CDF, Helm Charts etc."
  default     = "/tmp/"
}

variable "environment-prefix" {
  type        = string
  description = "A prefix to be prepended to every resource name"
  default     = "itom"
}

variable "vpc-id" {
  type        = string
  description = "The VPC to which to attach this subnet"
}

variable "vpc-cidr-block" {
  type        = string
  description = "The CIDR block assigned to the suite VPC"
}

variable "allowed-client-cidrs" {
  type        = list(string)
  description = "Limit the IP address ranges that are allowed to access the suite services"
}

variable "public-subnet-ids" {
  type        = list(string)
  description = "The IDs of all public subnets in the suites VPC"
}

variable "nat-gw-ip" {
  type        = string
  description = "Public IP address of NAT gateway of Kubernetes nodes"
}

variable "load-balancer-certificate-arn" {
  type        = string
  description = "Certificate to be used for the ALB/TLS NLBs"
}

variable "load-balancer-certificate-data" {
  type        = list(string)
  description = "Certificate to be used for the ALB/TLS NLBs - full certificate data"
}

variable "load-balancer-ca-certificate-data" {
  type        = list(string)
  description = "CA Certificate to be used for the ALB/TLS NLBs - full certificate data"
}

variable "hosted-zone" {
  type        = string
  description = "Optionally specify a hosted zone in which to add the load balancer as sub-domain"
  default     = ""
}

variable "oracle-instantclient-rpm-repo" {
  type        = string
  description = "Repository to be configured on bastion for fetching latest Oracle Instant Client RPM."
  default     = "https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-basic-linuxx64.rpm"
}

variable "oracle-sqlplus-rpm-repo" {
  type        = string
  description = "Repository to be configured on bastion for fetching latest Oracle SQLPLUS RPM."
  default     = "https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-sqlplus-linuxx64.rpm"
}

variable "bastion-username" {
  type        = string
  description = "The username to be used to log into Bastion; only necessary for custom bastion-ami-id"
  default     = "ec2-user"
}

variable "helm-version" {
  type        = string
  description = "Helm version."
  default     = ""
}
