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

variable "private-hosted-zone" {
  type        = string
  description = "Internal domain to use for private communication between suite services"
}

variable "public-hosted-zone" {
  type        = string
  description = "Domain record under which to create subdomains for suite services"
  default     = ""
}

variable "vpc-ic" {
  type        = string
  description = "VPC to which to attach the private hosted domain"
}