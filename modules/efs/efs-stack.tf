resource "aws_efs_file_system" "itom-nfs" {
  tags = merge(var.tags, {
    "Name" = "${var.environment-prefix}-itom-nfs"
  })
  encrypted = true
}

resource "aws_efs_mount_target" "itom-nfs-mount-targets" {
  count = length(var.target-subnet-ids)

  file_system_id  = aws_efs_file_system.itom-nfs.id
  subnet_id       = var.target-subnet-ids[count.index]
  security_groups = [aws_security_group.itom-nfs-security-group.id]
}

// used only to determine the VPC ID automatically
data "aws_security_group" "client-security-group" {
  id = var.client-security-group-ids[0]
}

resource "aws_security_group" "itom-nfs-security-group" {
  name   = "${var.environment-prefix}-nfs-security-group"
  vpc_id = data.aws_security_group.client-security-group.vpc_id

  ingress {
    from_port       = 2049
    protocol        = "TCP"
    to_port         = 2049
    security_groups = var.client-security-group-ids
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment-prefix}-nfs-security-group"
  })
}
