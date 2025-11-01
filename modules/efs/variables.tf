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

variable "target-subnet-ids" {
  type        = list(string)
  description = "The subnets to which to expose the NFS share. Should cover all potential clients."
  default     = []
}

variable "client-security-group-ids" {
  type        = list(string)
  description = "The security groups of clients that need to access the NFS share."
}