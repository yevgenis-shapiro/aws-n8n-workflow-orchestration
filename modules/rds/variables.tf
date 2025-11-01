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

variable "db-engine" {
  type        = string
  description = "Database engine"
}

variable "db-engine-version" {
  type        = string
  description = "Database engine version"
}

variable "database-name" {
  type        = string
  description = "Database name"
}

variable "vpc-id" {
  type        = string
  description = "The VPC to which to attach this subnet"
}

variable "db-subnet-group" {
  type        = string
  description = "DB Subnet group name for RDS installation"
}

variable "db-pg-parameter-group" {
  type        = string
  description = "DB Parameter group name for RDS installation."
}

variable "client-security-group-ids" {
  type        = list(string)
  description = "The security groups of clients that need to access the DB."
}

variable "db-admin-username" {
  type        = string
  description = "Username for the administration user of the database"
  default     = "dbadmin"
}

variable "db-admin-password" {
  type        = string
  description = "Password for the administration user of the database"
}

variable "db-instance-type" {
  type        = string
  description = "The instance type to use for running the database. See AWS homepage for available types"
}

variable "db-volume-size" {
  type        = number
  description = "Size in GiB of the storage volume used to store the database"
}

variable "ca_cert_identifier" {
  type        = string
  description = " Identifier of the CA certificate for the DB instance"
  default     = "rds-ca-rsa2048-g1"
}
