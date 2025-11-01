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
  description = "Which availability zones to use for the Database server"
}

variable "vpc-id" {
  type        = string
  description = "The VPC to which to attach this subnet"
}

variable "cidr-blocks" {
  type        = list(string)
  description = "CIDR blocks to be used for the Databases subnets"
}

variable "use_existing_vpc" {
  type        = bool
  description = "Set this to true if want to use your existing vpc and network configuration"
  default     = false
}

variable "existing_private_rds_subnet_ids" {
  type        = list(string)
  description = "IDs of two private subnets for RDS"
  default     = []
}