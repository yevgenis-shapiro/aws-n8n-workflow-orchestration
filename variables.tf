# ======================================================================================================================
# CLOUD RESOURCES IDENTIFICATION
# ======================================================================================================================
variable "environment_prefix" {
  type        = string
  description = "A prefix to be prepended to every resource name"
  default     = "itom-toolkit1"
}

variable "tags" {
  type        = map(string)
  description = "Tags to be attached to every resource"
  default     = {}
}

# ======================================================================================================================
# NETWORK CONFIGURATION
# ======================================================================================================================
variable "allowed_client_cidrs" {
  type        = list(string)
  description = "Limit the IP address ranges that are allowed to access suite services"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block to be used for all subnets of this VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_prefix_size" {
  type        = number
  description = "How many bits of the IP address should be reserved for the subnet prefix. E.g. VPC with /16 plus 4 bits prefix leaves 16 subnets, each /12"
  default     = 4
}

variable "private_hosted_zone" {
  type        = string
  description = "Internal domain to use for private communication between suite services"
  default     = "itombyok.internal-test"
}

variable "public_hosted_zone" {
  type        = string
  description = "Domain record under which to create subdomains for suite services"
  default     = ""
}

variable "k8s_namespaces_for_external_dns" {
  type        = list(string)
  description = "List of Kubernetes namespaces where External DNS needs to be enabled."
  default     = ["core", "optic-dl"]
}

# ======================================================================================================================
# KUBERNETES CLUSTER CONFIGURATION
# ======================================================================================================================
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

# Enable 'workers_multi_az' capability to consider the below number of AZs for EKS, otherwise the default is always 2
variable "number_eks_azs" {
  type        = number
  description = "Number of availability zones to use for EKS. Please check maximum number of AZs for your region first."
  default     = 3
}

variable "node_instance_type" {
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

variable "node_group_min_size" {
  type        = number
  description = "Minimum number of nodes of worker nodes to create"
  default     = 1
}

variable "node_group_max_size" {
  type        = number
  description = "Maximum number of nodes of worker nodes to create"
  default     = 10
}

variable "node_group_desired_size" {
  type        = number
  description = "Desired number of nodes of worker nodes to create"
  default     = 3
}

variable "enable_eks_control_plane_logs" {
  type        = bool
  default     = true
  description = "Set to true to enable eks control plane logs"
}

variable "eks_control_plane_logs" {
  type        = list(string)
  default     = ["api", "audit", "authenticator","controllerManager","scheduler"]
  description = "List of the desired control plane logging to enable"
}

variable "enable_kms_encryption_eks" {
  type        = bool
  description = "Set to true to enable secrets encryption for eks with kms key. Enabling this will create a kms key with rotation policy of 1 year"
  default     = false
}

# ======================================================================================================================
# BASTION NODE CONFIGURATION
# ======================================================================================================================
variable "itom_software_directory" {
  type        = string
  description = "Directory that contains various ITOM Software binaries such as CDF, Helm Charts etc."
  default     = "../itom-software"
}

variable "csi_driver_helmchart_version" {
  type        = string
  description = "CSI Driver Helm Chart version"
  default     = "2.10.1"
}

variable "bastion-ami-id" {
  type        = string
  description = "The AMI to use for bastion; change with care, several scripts need to run on the machine"
  default     = ""
}

variable "bastion-username" {
  type        = string
  description = "The username to be used to log into Bastion; only necessary for custom bastion-ami-id"
  default     = "ec2-user"
}

variable "helm-version" {
  type        = string
  description = "The version of Helm binaries to install on Bastion node"
  default     = ""
}

# ======================================================================================================================
# RDS DATABASE CONFIGURATION
# ======================================================================================================================
variable "database_engine" {
  type        = string
  description = "Database engine. Supported: postgres and oracle-ee"
  default     = "postgres"
}

variable "database_engine_version" {
  type        = string
  description = "Database engine version. E.g. for Postgres - 11.11, for Oracle - 19.0.0.0.ru-2021-04.rur-2021-04.r1"
  default     = "11.15"
}

variable "database_instance_type" {
  type        = string
  description = "The instance type to use for running the Postgres/Oracle database. See AWS homepage for available types"
  default     = "db.t3.xlarge"
}

variable "database_volume_size" {
  type        = number
  description = "Size in GiB of the storage volume used to store the database"
  default     = 100
}

variable "database_name" {
  type        = string
  description = "Database name"
  default     = "mydb"
}

variable "database_admin_username" {
  type        = string
  description = "Username of database admin user"
  default     = "dbadmin"
}

variable "database_admin_password" {
  type        = string
  description = "Password of database admin user"
  sensitive   = true
}

variable "create_postgres_parameter_group" {
  type        = bool
  description = "Create DB Parameter group resource permission."
  default     = false
}

# =============================== ADVANCED CONFIGURATION FOR RDS POSTGRES DATABASE =====================================
                        ### BELOW ARE THE CONFIGURABLE PARAMETERS FOR RDS POSTGRES PARAMETER GROUP
variable "effective_cache_size" {
  type        = number
  description = "Size in 8kB of the planners assumption about the size of the disk cache. Formula: {DBInstanceClassMemory/16384}"
  default     = 1000000
}

variable "maintenance_work_mem" {
  type        = number
  description = "Size in kB of the maximum memory to be used for maintenance operations. Formula: GREATEST({DBInstanceClassMemory*1024/63963136},65536)"
  default     = 262830
}

variable "max_connections" {
  type        = number
  description = "Sets the maximum number of concurrent connections. Formula: LEAST({DBInstanceClassMemory/9531392},5000)"
  default     = 1667
}

variable "shared_buffers" {
  type        = number
  description = "Size in 8kB of the number of shared memory buffers used by the server. Formula: {DBInstanceClassMemory/32768}"
  default     = 500000
}

variable "work_mem" {
  type        = number
  description = "Size in kB of the maximum memory to be used for query workspaces."
  default     = 4000
}

#
# =============================== EXISTING VPC CONFIGURATION =======================================================

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

variable "existing_private_rds_subnet_ids" {
  type        = list(string)
  description = "IDs of two private subnets for RDS"
  default     = []
}

variable "existing_private_vertica_subnet_id" {
  type        = string
  description = "ID of one private subnet for vertica"
  default     = "null"
}

variable "existing_private_eks_subnet_ids" {
  type        = list(string)
  description = "IDs of all the private subnets for eks. If 'workers_multi_az' variable is set to false, pass 2 subnet IDs.If 'workers_multi_az' variable is set to true, the number of subnet IDs should be equal to the value set for 'number_eks_azs'"
  default     = []
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

