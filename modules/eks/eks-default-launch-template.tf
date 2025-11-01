resource "aws_launch_template" "eks-default-launch-template" {

    block_device_mappings {
        device_name = "/dev/xvda"
        ebs {
        volume_size = var.node-disk-size
        volume_type = var.volume-type
        }
    }
    
    key_name               = local.allow_remote_access ? var.ssh-key-pair-name : null
    vpc_security_group_ids = local.allow_remote_access ? aws_eks_cluster.k8s-cluster.vpc_config[*].cluster_security_group_id : []

}