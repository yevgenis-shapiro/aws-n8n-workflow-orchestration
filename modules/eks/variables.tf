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

variable "k8s_version" {
  type        = string
  description = "Required K8s version"
  default     = "1.24"
}

variable "workers_multi_az" {
  type        = string
  description = "Place worker nodes on multiple availability zones"
  default     = false
}

variable "availability-zones" {
  type        = list(string)
  description = "Which availability zones to use for the Kubernetes master nodes"
}

variable "vpc-id" {
  type        = string
  description = "The VPC to which to attach this subnet"
}

variable "nat-gw-id" {
  type        = string
  description = "The NAT GW that worker nodes will use to access master public IP"
}

variable "cidr-blocks" {
  type        = list(string)
  description = "CIDR blocks to be used for the cluster subnets"
}

variable "node-instance-type" {
  type        = string
  description = "The instance type to deploy for EKS worker nodes"
  default     = "m5.2xlarge"
}

variable "node-ami-id" {
  type        = string
  description = "The AMI to be used to deploy EKS worker nodes"
  default     = ""
}

variable "node-user-data" {
  type        = string
  description = "Use for custom node-ami-id; Custom user data, should trigger connection to control plane"
  default     = ""
}

variable "node-group-min-size" {
  type        = number
  description = "Minimum number of nodes of worker nodes to create"
  default     = 1
}

variable "node-group-max-size" {
  type        = number
  description = "Maximum number of nodes of worker nodes to create"
  default     = 6
}

variable "node-group-desired-size" {
  type        = number
  description = "Desired number of nodes of worker nodes to create"
  default     = 3
}

variable "node-disk-size" {
  type        = number
  description = "Desired disk size for each worker node"
  default     = 100
}

variable "volume-type" {
  type        = string
  description = "Desired disk type for each worker node"
  default     = "gp3"
}

variable "ssh-key-pair-name" {
  type        = string
  default     = null
  description = "Name of an SSH key pair to use for login to worker node VM"
}

variable "internal_ingress_port_ranges" {
  description = "A list of objects, each with fields 'from' and 'to', specifying which ports (numbers) allow inbound communication to the worker nodes"
  type = list(object({
    from = number
    to   = number
  }))
  default = [
    {
      from = 1025
      to   = 3388
    },
    {
      from = 3390
      to   = 65535
    }
  ]
}

variable "eks_cluster_public_access_cidrs" {
  type        = list(string)
  description = "Limit the IP address ranges that are allowed to access EKS cluster endpoints"
}

variable "enable_eks_control_plane_logs" {
  type        = bool
  description = "Set to true to enable eks control plane logs"
  default     = true
}

variable "eks_control_plane_logs" {
  type        = list(string)
  description = "List of the desired control plane logging to enable"
  default     = ["api", "audit", "authenticator","controllerManager","scheduler"]
}

variable "enable_kms_encryption_eks" {
  type        = bool
  description = "Set to true to enable secrets encryption for eks with kms key. Enabling this will create a kms key with rotation policy of 1 year"
  default     = false
}

variable "use_existing_vpc" {
  type        = bool
  description = "Set this to true if want to use your existing vpc and network configuration"
  default     = false
}

variable "existing_private_eks_subnet_ids" {
  type        = list(string)
  description = "IDs of all the private subnets for eks. If 'workers_multi_az' variable is set to false, pass 2 subnet IDs.If 'workers_multi_az' variable is set to true, the number of subnet IDs should be equal to the value set for 'number_eks_azs'"
  default     = []
}