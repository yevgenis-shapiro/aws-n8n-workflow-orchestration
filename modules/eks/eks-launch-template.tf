resource "aws_launch_template" "eks-launch-template" {
  count = (local.use_custom_ami) ? 1 : 0

  name_prefix   = var.environment-prefix
  description   = "Custom launch template for EKS worker nodes in environment ${var.environment-prefix}"
  image_id      = var.node-ami-id
  instance_type = var.node-instance-type

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = var.node-disk-size
      volume_type = var.volume-type
    }
  }

  key_name               = local.allow_remote_access ? var.ssh-key-pair-name : null
  vpc_security_group_ids = local.allow_remote_access ? aws_eks_cluster.k8s-cluster.vpc_config[*].cluster_security_group_id : []

  user_data = base64encode(replace(var.node-user-data, "$${cluster-name}", aws_eks_cluster.k8s-cluster.name))

  tags = var.tags
}