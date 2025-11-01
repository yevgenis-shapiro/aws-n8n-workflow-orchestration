variable "environment-prefix" {
  type        = string
  description = "A prefix to be prepended to every resource name."
  default     = "itom"
}

variable "tags" {
  type        = map(string)
  description = "Tags to be attached to every resource"
  default     = {}
}
variable "database-engine" {
  type        = string
  description = "Database engine."
}

variable "database-engine-version" {
  type        = string
  description = "Database engine version."
}

variable "effective-cache-size" {
  type        = number
  description = "Size in 8kB of the planners assumption about the size of the disk cache."
}

variable "maintenance-work-mem" {
  type        = number
  description = "Size in kB of the maximum memory to be used for maintenance operations."
}

variable "max-connections" {
  type        = number
  description = "Sets the maximum number of concurrent connections."
}

variable "shared-buffers" {
  type        = number
  description = "Size in 8kB of the number of shared memory buffers used by the server."
}

variable "work-mem" {
  type        = number
  description = "Size in kB of the maximum memory to be used for query workspaces."
}