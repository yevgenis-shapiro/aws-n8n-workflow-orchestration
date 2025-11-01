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

variable "availability-zones" {
  type        = list(string)
  description = "Availability zones to use for the public subnets"
}

variable "vpc-id" {
  type        = string
  description = "The VPC to which to attach this subnet"
}

variable "cidr-blocks" {
  type        = list(string)
  description = "CIDR blocks to be used for the public subnets"
}

variable "use_existing_vpc" {
  type        = bool
  description = "Set this to true if want to use your existing vpc and network configuration"
  default     = false
}

variable "existing_public_subnet_ids" {
  type        = list(string)
  description = "IDs of all the public subnets. If 'workers_multi_az' variable is set to false, pass 2 subnet IDs.If 'workers_multi_az' variable is set to true, the number of subnet IDs should be equal to the value set for 'number_eks_azs'"
  default     = []
}

variable "existing_nat_gw_eip" {
  type        = string
  description = "Public Elastic IP attached to the NAT gateway"
  default     = "null"
}