terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.65.0 , < 5.0.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
  ignore_tags {
    key_prefixes = ["kubernetes.io/cluster"]
  }
}

data "aws_availability_zones" "availability-zones" {}

resource "random_id" "deployment-id" {
  byte_length = 8
}

locals {
  // How many subnets / CIDRs to generate for each group/service ==> we call these "CIDR groups"
  cidr_groups = {
    public  = (var.workers_multi_az) ? var.number_eks_azs : 2
    eks     = (var.workers_multi_az) ? var.number_eks_azs : 2
    rds     = 2
    vertica = 1
  }
}

#// UDX RPM FILE
#module "udx_rpm_path" {
#  #count                   = var.skip_vertica_deployment ? 0 : 1
#  source                  = "../tf-modules/udx-rpm-detection"
#  itom_software_directory = "${path.module}/../../itom-software"
#}

// VPC
module "vpc" {
  source         = "./modules/vpc"
  vpc-cidr-block = var.vpc_cidr_block

  use_existing_vpc = var.use_existing_vpc
  existing_vpc_id  = var.existing_vpc_id

  environment-prefix = var.environment_prefix
  tags               = var.tags
}

// PUBLIC SUBNET
module "public-subnet" {
  source = "./modules/public-subnet"

  availability-zones = slice(data.aws_availability_zones.availability-zones.names, 0, local.cidr_groups.public)
  vpc-id             = module.vpc.vpc-id
  cidr-blocks        = local.grouped_cidrs["public"]

  use_existing_vpc           = var.use_existing_vpc
  existing_public_subnet_ids = var.existing_public_subnet_ids
  existing_nat_gw_eip        = var.existing_nat_gw_eip

  environment-prefix = var.environment_prefix
  tags               = merge(var.tags, {
    "kubernetes.io/role/elb" = 1
  })
}

// DNS ZONE
module "dns-zone" {
  source = "./modules/hosted-zone"

  private-hosted-zone = var.private_hosted_zone
  public-hosted-zone  = var.public_hosted_zone
  vpc-ic              = module.vpc.vpc-id

  environment-prefix = var.environment_prefix
  tags               = var.tags
}

// SSH KEY PAIR
module "ssh-key-pair" {
  source = "./modules/keypair"

  environment-prefix = var.environment_prefix
  tags               = var.tags
}

// BASTION VM
module "bastion" {
  source = "./modules/bastion"

  vpc-id                = module.vpc.vpc-id
  subnet-id             = module.public-subnet.subnet-id[0]
  dns-zone-ids          = [module.dns-zone.dns-zone-id]
  dns-update-policy-arn = module.dns-zone.update-domain-policy-arn
  allowed-client-cidrs  = var.allowed_client_cidrs
  bastion-ami-id        = var.bastion-ami-id

  k8s-access-role-name   = module.eks-cluster.client-role-name
  eks-cluster-name       = module.eks-cluster.cluster-name
  efs-arn                = module.efs.efs-arn
  rds-arns               = [module.database.db-arn]
  private-hosted-zone-id = module.dns-zone.dns-private-zone-id
  public-hosted-zone-id  = module.dns-zone.dns-public-zone-id
  certificate-arn        = module.dns-zone.acm-certificate-arn
  ssh-key-pair-name      = module.ssh-key-pair.key-pair-name
  ssh-private-key        = module.ssh-key-pair.key-pair-private-ssh-key

  environment-prefix = var.environment_prefix
  tags               = var.tags
  deployment-id      = random_id.deployment-id.id

}

// EKS CLUSTER
module "eks-cluster" {
  source = "./modules/eks"

  k8s_version      = var.k8s_version
  workers_multi_az = var.workers_multi_az

  ssh-key-pair-name  = module.ssh-key-pair.key-pair-name
  availability-zones = slice(data.aws_availability_zones.availability-zones.names, 0, var.number_eks_azs)

  vpc-id      = module.vpc.vpc-id
  cidr-blocks = local.grouped_cidrs["eks"]
  nat-gw-id   = module.public-subnet.nat-gw-id

  # defaults needed for opsbridge-suite, the k8s omi svc currently targets port 443
  internal_ingress_port_ranges = [
    {
      from = 383 # BBC-specific
      to   = 383
    },
    {
      from = 443 # OBM-specific
      to   = 443
    },
    {
      from = 1025
      to   = 3388
    },
    {
      from = 3390
      to   = 65535
    }
  ]

  node-instance-type      = var.node_instance_type
  node-ami-id             = var.node-ami-id
  node-user-data          = var.node-user-data
  node-group-min-size     = var.node_group_min_size
  node-group-desired-size = var.node_group_desired_size
  node-group-max-size     = var.node_group_max_size

  eks_cluster_public_access_cidrs = var.allowed_client_cidrs

  enable_eks_control_plane_logs = var.enable_eks_control_plane_logs
  eks_control_plane_logs        = var.eks_control_plane_logs
  enable_kms_encryption_eks     = var.enable_kms_encryption_eks

  use_existing_vpc                = var.use_existing_vpc
  existing_private_eks_subnet_ids = var.existing_private_eks_subnet_ids

  environment-prefix = var.environment_prefix
  tags               = var.tags
}

// NFS SHARE
module "efs" {
  source = "./modules/efs"

  target-subnet-ids         = flatten([module.eks-cluster.subnet-ids])
  client-security-group-ids = flatten([module.bastion.security-groups, module.eks-cluster.security-group-id])

  environment-prefix = var.environment_prefix
  tags               = var.tags
}

// RDS SUBNETS
module "database-subnets" {
  source = "./modules/rds-subnets"

  tags   = var.tags
  vpc-id = module.vpc.vpc-id

  availability-zones = [
    data.aws_availability_zones.availability-zones.names[0],
    data.aws_availability_zones.availability-zones.names[1]
  ]

  use_existing_vpc                = var.use_existing_vpc
  existing_private_rds_subnet_ids = var.existing_private_rds_subnet_ids

  cidr-blocks = local.grouped_cidrs["rds"]
}

// RDS POSTGRES PARAMETER GROUP
module "database-postgres-parameter-group" {
  count  = var.create_postgres_parameter_group ? 1 : 0
  source = "./modules/rds-pg-parameter-group"

  environment-prefix      = var.environment_prefix
  database-engine         = var.database_engine
  database-engine-version = var.database_engine_version
  tags                    = var.tags

  effective-cache-size = var.effective_cache_size
  maintenance-work-mem = var.maintenance_work_mem
  max-connections      = var.max_connections
  shared-buffers       = var.shared_buffers
  work-mem             = var.work_mem
}

// RDS
module "database" {
  source = "./modules/rds"

  db-engine         = var.database_engine
  db-engine-version = var.database_engine_version
  database-name     = var.database_name
  db-instance-type  = var.database_instance_type
  db-admin-username = var.database_admin_username
  db-admin-password = var.database_admin_password
  db-volume-size    = var.database_volume_size

  db-subnet-group       = module.database-subnets.db-subnet-group-name
  db-pg-parameter-group = var.create_postgres_parameter_group ? module.database-postgres-parameter-group[0].db-parameter-group-name : ""

  vpc-id                    = module.vpc.vpc-id
  client-security-group-ids = flatten([module.bastion.security-groups, module.eks-cluster.security-group-id])

  environment-prefix = var.environment_prefix
  tags               = var.tags

  depends_on = [module.database-postgres-parameter-group]
}

// DETECT CORRECT KUBECTL DOWNLOAD URL
module "kubectl-finder" {
  source          = "./modules/kubectl-finder"
  kubectl_version = var.k8s_version
}

// BASTION PREPARATION
module "bastion-preparation" {
  source = "./modules/bastion-prep"

  bastion-public-ip = module.bastion.public-ip
  ssh-private-key   = module.ssh-key-pair.key-pair-private-ssh-key

  vpc-id                            = module.vpc.vpc-id
  vpc-cidr-block                    = module.vpc.vpc-cidr
  allowed-client-cidrs              = var.allowed_client_cidrs
  public-subnet-ids                 = module.public-subnet.subnet-id
  nat-gw-ip                         = module.public-subnet.nat-gw-ip
  load-balancer-certificate-arn     = module.dns-zone.acm-certificate-arn
  load-balancer-certificate-data    = module.dns-zone.acm-self-signed-certificate-arn-data
  load-balancer-ca-certificate-data = module.dns-zone.acm-self-signed-ca-certificate-arn-data
  environment-prefix                = var.environment_prefix
  hosted-zone                       = module.dns-zone.dns-zone-id
  database-engine                   = var.database_engine
  database-engine-version           = var.database_engine_version
  bastion-username                  = var.bastion-username
  helm-version                      = var.helm-version

  efs_dns = element(module.efs.nfs-dns-names, 0)

  kubectl_download_location = module.kubectl-finder.kubectl_download_url
  eks_cluster_name          = module.eks-cluster.cluster-name
  eks_cluster_region        = module.eks-cluster.cluster-region

  itom-software-directory = var.itom_software_directory

  depends_on = [module.bastion, module.eks-cluster, module.efs]

}


// LOAD BALANCER CONTROLLER
module "load-balancer-controller" {
  source                       = "./modules/load-balancer-controller"
  environment-prefix           = var.environment_prefix
  tags                         = var.tags
  eks-oidc-issuer              = module.eks-cluster.eks-oidc-issuer-url
  oidc-provider                = module.eks-cluster.eks-oidc-provider-arn
  k8s-cluster-name             = module.eks-cluster.cluster-name
  k8s-cluster-endpoint         = module.eks-cluster.cluster-endpoint
  k8s-cluster-ca-data          = module.eks-cluster.cluster-certificate-authority-data
  bastion-public-ip            = module.bastion.public-ip
  bastion-username             = var.bastion-username
  ssh-private-key              = module.ssh-key-pair.key-pair-private-ssh-key
  helm-version                 = module.bastion-preparation.helm_version
}


// EBS CSI DRIVER
module "ebs-csi-driver" {
  source = "./modules/ebs-csi"

  environment-prefix           = var.environment_prefix
  tags                         = var.tags
  eks-oidc-issuer              = module.eks-cluster.eks-oidc-issuer-url
  oidc-provider                = module.eks-cluster.eks-oidc-provider-arn
  bastion-public-ip            = module.bastion.public-ip
  ssh-private-key              = module.ssh-key-pair.key-pair-private-ssh-key
  csi-driver-helmchart-version = var.csi_driver_helmchart_version
  bastion-username             = var.bastion-username

  depends_on = [module.bastion-preparation]
}

// EXTERNAL DNS
module "external-dns" {
  source = "./modules/external-dns"

  environment-prefix              = var.environment_prefix
  tags                            = var.tags
  eks-oidc-issuer                 = module.eks-cluster.eks-oidc-issuer-url
  oidc-provider                   = module.eks-cluster.eks-oidc-provider-arn
  bastion-public-ip               = module.bastion.public-ip
  ssh-private-key                 = module.ssh-key-pair.key-pair-private-ssh-key
  k8s-namespaces-for-external-dns = var.k8s_namespaces_for_external_dns
  depends_on                      = [module.bastion-preparation]
  bastion-username                = var.bastion-username
  dns-domain-name                 = module.dns-zone.dns-domain-name
  limit-queries                   = true
}
