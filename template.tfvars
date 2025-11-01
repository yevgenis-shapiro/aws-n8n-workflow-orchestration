
environment_prefix = "n8n"
tags               = {
  "Owner" = ""
}

allowed_client_cidrs = ["0.0.0.0/0"]        # Who can access the suite services?
node_instance_type        = "m5.large"      # What's the instance type for the Kubernetes worker nodes?
node_group_desired_size   = 4               # How many nodes are needed (up to 10 or check variables.tf for more options)?
k8s_version = "1.33"
enable_kms_encryption_eks = false           # Set to true to enable secrets encryption for eks with kms key. Enabling this will create a kms key with rotation policy of 1 year

database_engine         = "postgres"        # What RDS database to deploy? Supported values: postgres, oracle-ee
database_engine_version = "16.6"            # Which version of the database is needed?
database_instance_type  = "db.t3.small"     # What's the database instance type? Consult: https://aws.amazon.com/rds/instance-types/
database_volume_size    = 100               # How much storage (GiB) should the database use?

database_name           = "n8n"
database_admin_username = "dbadmin"
database_admin_password = "q1w2e3r4100!"    # 8-128 characters, combination of letters, digits, and special characters
create_postgres_parameter_group = false

#Multi AZ configuration
workers_multi_az = false                    #Place worker nodes on multiple availability zones
# Enable 'workers_multi_az' capability to consider the below number of AZs for EKS, otherwise the default is always 2
number_eks_azs   = 2                        #Number of availability zones to use for EKS. Please check maximum number of AZs for your region first.
vpc_cidr_block = "10.0.0.0/16"  # CIDR block to be used for VPC. If you are using your existing VPC, update this variable with the CIDR range of your existing VPC

use_existing_vpc                   = false  # Set this to true if you want to use your existing VPC and network configuration. Below parameters are applicable if this is set to true
existing_vpc_id                    = "null" # ID of your existing VPC
existing_private_rds_subnet_ids    = []     # IDs of two private subnets for RDS
existing_private_vertica_subnet_id = "null" # ID of one private subnet for vertica
existing_nat_gw_eip                = "null" # Public Elastic IP attached to the NAT gateway
existing_public_subnet_ids         = []     # IDs of all the public subnets. If 'workers_multi_az' variable is set to false, pass 2 subnet IDs.If 'workers_multi_az' variable is set to true, the number of subnet IDs should be equal to the value set for 'number_eks_azs'
existing_private_eks_subnet_ids    = []     # IDs of all the private subnets for eks. If 'workers_multi_az' variable is set to false, pass 2 subnet IDs.If 'workers_multi_az' variable is set to true, the number of subnet IDs should be equal to the value set for 'number_eks_azs'




