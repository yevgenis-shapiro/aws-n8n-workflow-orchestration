//TODO: find a better place for this
//TODO: ssh connection allow for worker node
//TODO : chose auto image for worker

data "aws_eks_cluster_auth" "k8s-auth-data" {
  name = aws_eks_cluster.k8s-cluster.id
}

locals {
  # How many nodes to put in each node-group (assuming an even distribution of the nodes on the node groups)
  nodes_per_az = floor(var.node-group-desired-size / length(var.availability-zones))

  # If even distribution does not work out, how many additional nodes do we need to distribute?
  extra_nodes = var.node-group-desired-size % length(var.availability-zones)

  # Based on the numbers above, generate a list of node group sizes (e.g. [2, 2] for 4 nodes on 2 groups or
  # [3, 3, 2] for 8 nodes on 3 groups
  group_sizes = var.workers_multi_az ? [for idx, zone in var.availability-zones : (local.nodes_per_az + ((idx < local.extra_nodes) ? 1 : 0))] : [var.node-group-desired-size]

  # Minimal node count has to be spread over all available node groups. Also, no node group should have a min size
  # of less than 1
  node_group_min_size = var.workers_multi_az ? (max(1, floor(var.node-group-min-size / length(var.availability-zones)))) : var.node-group-min-size
}

locals {
  use_custom_ami      = var.node-ami-id != ""
  allow_remote_access = var.ssh-key-pair-name != null && var.ssh-key-pair-name != ""

}

provider "kubernetes" {
  host                   = aws_eks_cluster.k8s-cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.k8s-cluster.certificate_authority[0].data)
  //  token                  = data.aws_eks_cluster_auth.k8s-auth-data.token
  exec {
    api_version = "client.authentication.k8s.io/v1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.k8s-cluster.name]
    command     = "aws"
  }
}

resource "aws_kms_key" "eks_key" {
  count                   = var.enable_kms_encryption_eks ? 1 : 0
  description             = "KMS key for eks encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = var.tags
}


resource "aws_eks_cluster" "k8s-cluster" {
  name     = "${var.environment-prefix}-cluster"
  role_arn = aws_iam_role.eks-cluster-worker-role.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids              = var.use_existing_vpc ? var.existing_private_eks_subnet_ids : aws_subnet.private-subnet-workers[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = aws_security_group.eks_control_plane_sg[*].id
    public_access_cidrs     = var.eks_cluster_public_access_cidrs
  }

  dynamic "encryption_config" {
    for_each = var.enable_kms_encryption_eks ? [1] : []
    content {
      resources = [ "secrets" ]
      provider {
        key_arn = aws_kms_key.eks_key[0].arn
      }
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.k8s-role-cluster-policy,
    aws_iam_role_policy_attachment.k8s-role-vpc-resource-controller
  ]

  enabled_cluster_log_types = var.enable_eks_control_plane_logs ? var.eks_control_plane_logs : null

  tags = var.tags
}

# Using default AMI for the worker nodes
resource "aws_eks_node_group" "k8s-cluster-node-group_default_ami" {
  count           = (local.use_custom_ami) ? 0 : length(local.group_sizes)
  ami_type        = "BOTTLEROCKET_x86_64"
  instance_types  = [var.node-instance-type]
  depends_on      = [kubernetes_config_map.aws-auth-cm] // due to creation of aws-auth configmap when adding the node group
  cluster_name    = aws_eks_cluster.k8s-cluster.name
  node_group_name = "${var.environment-prefix}-node-group-${count.index}"
  node_role_arn   = aws_iam_role.eks-cluster-worker-role.arn
  subnet_ids      = var.use_existing_vpc ? [var.existing_private_eks_subnet_ids[count.index]] : [aws_subnet.private-subnet-workers[count.index].id]

  scaling_config {
    min_size     = local.node_group_min_size
    max_size     = var.node-group-max-size
    desired_size = local.group_sizes[count.index]
  }

  launch_template {
    id      = aws_launch_template.eks-default-launch-template.id
    version = "$Latest"
  }

  labels = {
    node_type = "worker"
    Worker    = "label"
    role      = "loadbalancer"
  }

  tags = var.tags
}

# Use custom AMI for worker nodes
resource "aws_eks_node_group" "k8s-cluster-node-group_custom_ami" {
  count           = (local.use_custom_ami) ? length(local.group_sizes) : 0
  ami_type        = "CUSTOM"
  depends_on      = [kubernetes_config_map.aws-auth-cm] // due to creation of aws-auth configmap when adding the node group
  cluster_name    = aws_eks_cluster.k8s-cluster.name
  node_group_name = "${var.environment-prefix}-node-group-${count.index}"
  node_role_arn   = aws_iam_role.eks-cluster-worker-role.arn
  subnet_ids      = var.use_existing_vpc ? [var.existing_private_eks_subnet_ids[count.index]] : [aws_subnet.private-subnet-workers[count.index].id]

  scaling_config {
    min_size     = local.node_group_min_size
    max_size     = var.node-group-max-size
    desired_size = local.group_sizes[count.index]
  }

  dynamic "launch_template" {
    for_each = aws_launch_template.eks-launch-template
    content {
      id      = launch_template.value.id
      version = launch_template.value.latest_version
    }
  }

  labels = {
    node_type = "worker"
    Worker    = "label"
    role      = "loadbalancer"
  }

  tags = var.tags
}

resource "aws_iam_role" "eks-cluster-worker-role" {
  name = "${var.environment-prefix}-k8s-worker-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "eks.amazonaws.com",
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "k8s-role-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-worker-role.name
}

resource "aws_iam_role_policy_attachment" "k8s-role-vpc-resource-controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-cluster-worker-role.name
}

resource "aws_iam_role_policy_attachment" "k8s-role-eks-worker-node-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-cluster-worker-role.name
}

resource "aws_iam_role_policy_attachment" "k8s-role-ec2-container-registry-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-cluster-worker-role.name
}

resource "aws_iam_role" "k8s-client-role" {
  name = "${var.environment-prefix}-k8s-client-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = var.tags
}

/*resource "aws_iam_role_policy_attachment" "k8s-client-role-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.k8s-client-role.name
}

resource "aws_iam_role_policy_attachment" "k8s-client-role-vpc-resource-controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.k8s-client-role.name
}

resource "aws_iam_role_policy_attachment" "k8s-client-role-eks-worker-node-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.k8s-client-role.name
}*/

resource "aws_iam_role_policy_attachment" "k8s-client-role-eks-worker-service-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.k8s-client-role.name
}

resource "aws_iam_policy" "ecr-access-policy" {
  name   = "${var.environment-prefix}-ecr-access-policy"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:CreateRepository",
                "ecr:DescribeRepositories",
                "ecr:ListImages"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "k8s-client-role-ecr-access-policy" {
  policy_arn = aws_iam_policy.ecr-access-policy.arn
  role       = aws_iam_role.k8s-client-role.name
}

resource "aws_subnet" "private-subnet-workers" {
  count             = var.use_existing_vpc? 0 : min(length(var.availability-zones), length(var.cidr-blocks))
  cidr_block        = var.cidr-blocks[count.index]
  vpc_id            = var.vpc-id
  availability_zone = var.availability-zones[count.index]

  tags = merge(var.tags, {
    "Name"                            = "workers-${count.index}"
    "subnet-role"                     = "workers"
    "kubernetes.io/role/internal-elb" = 1
  })
}

resource "aws_route_table" "workers-route" {
  count             = var.use_existing_vpc? 0 : 1
  vpc_id = var.vpc-id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.nat-gw-id
  }

  tags = var.tags
}

resource "aws_route_table_association" "workers-route-to-subnet" {
  count = var.use_existing_vpc? 0 : length(aws_subnet.private-subnet-workers)

  route_table_id = aws_route_table.workers-route[0].id
  subnet_id      = aws_subnet.private-subnet-workers[count.index].id
}

resource "kubernetes_config_map" "aws-auth-cm" {
  depends_on = [aws_eks_cluster.k8s-cluster, data.aws_eks_cluster_auth.k8s-auth-data]
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = templatefile("${path.module}/aws-auth-cm.yml", {
      cluster_client_role_arn = aws_iam_role.k8s-client-role.arn
      cluster_role_arn        = aws_iam_role.eks-cluster-worker-role.arn
    })
  }
}

data "aws_ecr_authorization_token" "ecr-private-token" {}

data "aws_region" "current" {}

// Give the cluster role inside K8s enough access to do its work
data "aws_caller_identity" "current-user" {}
