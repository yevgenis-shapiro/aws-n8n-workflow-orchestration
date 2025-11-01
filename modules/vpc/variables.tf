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

variable "vpc-cidr-block" {
  type        = string
  description = "CIDR block to be used for all subnets of this VPC"
  default     = "10.0.0.0/16"
}

variable "use_existing_vpc" {
  type        = bool
  description = "Set this to true if want to use your existing vpc and network configuration"
  default     = false
}

variable "existing_vpc_id" {
  type        = string
  description = "ID of your existing vpc"
  default     = "null"
}