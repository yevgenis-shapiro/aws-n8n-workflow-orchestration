variable "environment_prefix" {
  default     = "itom"
  type        = string
  description = "A prefix to be prepended to every resource name"
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Tags to be attached to every resource"
}

variable "vertica_node_instance_type" {
  default     = "r4.4xlarge"
  type        = string
  description = "AWS EC2 Instance Type for Vertica node. AllowedValues : c5.4xlarge, c5.9xlarge, c4.4xlarge, c4.8xlarge, m5.4xlarge, m5.8xlarge, m5.12xlarge, m4.4xlarge, m4.10xlarge, r5.4xlarge, r5.8xlarge, r5.12xlarge, r4.4xlarge, r4.8xlarge, r4.16xlarge"
}

variable "vertica_node_count" {
  default     = 3
  type        = number
  description = "Minimum number of vertica nodes to create"
}

variable "vertica_shard_count" {
  type        = number
  description = "Number of shards to create for vertica nodes"
  default     = 6
}

variable "vertica-version" {
  type        = string
  description = "Specify the Vertica version you want to deploy (format major.minor.patch)"
  default     = "11.1.1"
}

variable "multi_tenancy" {
  type        = bool
  description = "Set to true if you want to enable multi-tenancy in ODL"
  default     = false
}

variable "enable_s3_versioning" {
  type        = bool
  description = "Set to true if you want to enable versioning for s3 bucket(Applicable only for Vertica Eon Mode)"
  default     = true
}

variable "custom-ami-id" {
  type        = string
  description = "Optionally specify an alternative AMI ID to be used for deploying Vertica; overrides vertica-version; AMI ID should be of the version set for vertica-version variable"
  default     = ""
}

variable "use_existing_vpc" {
  type        = bool
  description = "Set this to true if want to use your existing vpc and network configuration"
  default     = false
}

variable "vpc_id" {
  type        = string
  description = "VPC to be associated"
}

variable "vpc-cidr-block" {
  type        = string
  description = "CIDR block to be used for Vertica cluster subnet"
}

variable "nat_gateway_id" {
  type        = string
  description = "The NAT gateway that Vertica nodes will use to access internet"
}

variable "ssh_keypair_name" {
  type        = string
  description = "SSH Key Pair to be associated with EC2 instances"
}

variable "ssh_public_key" {
  description = "The SSH public key for the new user"
  type        = string
}

variable "existing_private_vertica_subnet_id" {
  type        = string
  description = "ID of one private subnet for vertica"
  default     = "null"
}

variable "bastion_public_ip" {
  type        = string
  description = "Bastion host public IP address"
}

variable "bastion-username" {
  type        = string
  description = "The username to be used to log into Bastion; only necessary for custom bastion-ami-id"
  default     = "ec2-user"
}

variable "ssh_private_key" {
  type        = string
  description = "Private key for bastion remote access through ssh"
}

variable "ssh_private_key_file" {
  type        = string
  description = "ssh private key file name"
}

variable "vertica_ro_username" {
  default     = "db_ro"
  type        = string
  description = "Vertica readonly database user name"
}

variable "vertica_ro_password" {
  type        = string
  description = "Vertica readonly database password"
}

variable "vertica_rw_username" {
  default     = "db_rw"
  type        = string
  description = "Vertica read write database user name"
}

variable "vertica_rw_password" {
  type        = string
  description = "Vertica read write database password"
}

variable "pulsar_udx_file" {
  default     = ["itom-di-pulsarudx-2.3.0-36.x86_64.rpm"]
  type        = list(string)
  description = "pulsar udx file name"
}

variable "skip_dbinit" {
  type        = bool
  description = "Skip initialization of database through dbinit.sh. Multi-tenant deployments only."
  default     = false
}

variable "vertica_license_file" {
  default     = ""
  type        = string
  description = "vertica license file name"
}

variable "vertica_database_name" {
  default     = "itomdb"
  type        = string
  description = "Vertica database name"
}

variable "vertica_username" {
  default     = "dbadmin"
  type        = string
  description = "Vertica database user name"
}

variable "vertica_dba_group" {
  default     = "verticadba"
  type        = string
  description = "Vertica database user name"
}

variable "vertica_password" {
  type        = string
  description = "Vertica database password"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block to be used for all subnets of this VPC"
  default     = ""
}

variable "vertica-mode" {
  type        = string
  description = "Specify the Vertica mode you want to deploy. AllowedValues : Eon Mode, Enterprise"
  default     = "Enterprise"
}

variable "vertica12-node-data-volume-type" {
  type        = string
  description = "Vertica 12 Node Data Volume type. Select from EBS General Purpose SSD (gp3) or EBS Provisioned IOPS SSD (io1). AllowedValues : gp3, io1"
  default     = "gp3"
}

#Check if isn't often changed
variable "vertica_node_data_volume_size" {
  type        = number
  description = "EBS Data Volume (GB) per volume (Total 8 such volumes for each Vertica node). MinValue: 4, MaxValue: 16384"
  default     = 75
}

variable "vertica_node_data_volume_iops" {
  type        = number
  description = "Provisioned IOPs for EBS, applicable for io1 Data Volume Type only. MinValue: 100, MaxValue: 32000"
  default     = 2000
}

variable "vertica12-node-catalog-volume-type" {
  type        = string
  description = "Vertica Node catalog Volume type. Select either EBS General Purpose SSD (gp3) or EBS Provisioned IOPS SSD (io1). AllowedValues : gp3, io1"
  default     = "gp3"
}

variable "vertica_node_catalog_volume_size" {
  type        = number
  description = "EBS Catalog volume size (GB) per Available Node. MinValue: 50, MaxValue: 1000"
  default     = 50
}

variable "vertica_node_catalog_volume_iops" {
  type        = number
  description = "Provisioned IOPs for EBS, applicable for io1 Catalog Volume Type only. MinValue: 100, MaxValue: 32000"
  default     = 2000
}

variable "vertica12-node-temp-volume-type" {
  type        = string
  description = "Vertica Node Temp Volume type. Select either EBS General Purpose SSD (gp3) or EBS Provisioned IOPS SSD (io1). AllowedValues : gp3, io1"
  default     = "gp3"
}

variable "vertica_node_temp_volume_size" {
  type        = number
  description = "EBS Temp volume size (GB) per Available Node. MinValue: 50, MaxValue: 1000"
  default     = 50
}

variable "vertica_node_temp_volume_iops" {
  type        = number
  description = "Provisioned IOPs for EBS, applicable for io1 Temp Volume Type only. MinValue: 100, MaxValue: 32000"
  default     = 2000
}

variable "vertica_node_root_block_volume_type" {
  type        = string
  description = "Vertica Node root block device Volume type."
  default     = "gp3"
}

variable "vertica_timezone" {
  default     = "America/New_York"
  type        = string
  description = "Vertica timezone"
}

variable "vertica_mc_for_monitoring" {
  type        = bool
  description = "Set this to true if want to deploy vertica mc for monitoring"
  default     = false
}

variable "public_subnet_id" {
  type        = string
  description = "Subnet ID belongs to the above VPC, must be PUBLIC"
}

variable "vertica_mc_db_admin" {
  default     = "uidbadmin"
  type        = string
  description = "Vertica MC administrator login"
}

variable "vertica_mc_db_admin_password" {
  type        = string
  description = "Vertica MC administrator password, 8-30 characters. Must contain upper and lower case letter, number, and one of the special characters ~ ! @ # $ % ^ & * ( ) _ + = [ ] / ? > < . ,- "
}

variable "vertica_mc_instance_type" {
  default     = "c4.xlarge"
  type        = string
  description = "AWS EC2 Instance Type for Vertica Management Console. Allowed values: c5.large, c4.large, c5.xlarge, c4.xlarge"
}

variable "vertica_mc_aws_authenticate" {
  default     = "IAM Role Instance Profile"
  type        = string
  description = "Authentication method for Vertica AWS instance provisioning and cluster management. Allowed values: IAM Role Instance Profile, AWS Access Keys"
}
variable "vertica_mc_cidr_block" {
  type        = string
  description = "CIDR block to be used for Vertica MC subnet"
}
