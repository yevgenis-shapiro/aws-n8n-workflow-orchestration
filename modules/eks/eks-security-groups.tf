data "aws_vpc" "vpc" {
  id = var.vpc-id
}

# The k8s cluster creates a default security group that is applied to all worker nodes.
# It seems that, by default, this group allows all outbound traffic.

resource "aws_security_group_rule" "k8s_cluster_core_dns_tcp" {
  security_group_id = aws_eks_cluster.k8s-cluster.vpc_config[0].cluster_security_group_id
  type = "ingress"
  protocol = "tcp"
  from_port = 53
  to_port = 53
  source_security_group_id = aws_eks_cluster.k8s-cluster.vpc_config[0].cluster_security_group_id
  description = "Allows Kubernetes nodes to reach the cluster DNS service and resolve host names correctly."
}

resource "aws_security_group_rule" "k8s_cluster_core_dns_udp" {
  security_group_id = aws_eks_cluster.k8s-cluster.vpc_config[0].cluster_security_group_id
  type = "ingress"
  protocol = "udp"
  from_port = 53
  to_port = 53
  source_security_group_id = aws_eks_cluster.k8s-cluster.vpc_config[0].cluster_security_group_id
  description = "Allows Kubernetes nodes to reach the cluster DNS service and resolve host names correctly."
}

resource "aws_security_group_rule" "k8s_workers_ingress" {
  count = length(var.internal_ingress_port_ranges)
  security_group_id = aws_eks_cluster.k8s-cluster.vpc_config[0].cluster_security_group_id
  type = "ingress"
  protocol = "tcp"
  from_port = var.internal_ingress_port_ranges[count.index].from
  to_port = var.internal_ingress_port_ranges[count.index].to
  source_security_group_id = aws_eks_cluster.k8s-cluster.vpc_config[0].cluster_security_group_id
  description = "Allows Kubernetes nodes to communicate with one another and with internal load balancers"
}

# Additional groups can be used for communication with anything outside the cluster and the control plane.

resource "aws_security_group" "eks_control_plane_sg" {
  name = "${var.environment-prefix}_eks_control_plane_sg"
  description = "EKS Control Plane Security Group. Allows communication from VPC."
  vpc_id = var.vpc-id
}

resource "aws_security_group_rule" "control_plane_ingress_allow_all_vpc_https" {
  security_group_id = aws_security_group.eks_control_plane_sg.id
  type = "ingress"
  protocol = "tcp"
  from_port = 443
  to_port = 443
  cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  description = "Allows communication with the control plane from any resource within the VPC"
}
