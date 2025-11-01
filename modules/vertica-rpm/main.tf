locals {
  name                 = replace("${var.environment_prefix}-vertica-mc-stack", "/\\W/", "-")
  remote_login_type    = "ssh"
  bastion_username     = var.bastion-username
  remote_login_timeout = "10m"
  vertica_mc_eula      = "Yes"
}

resource "aws_subnet" "vertica_subnet" {
  count      = var.use_existing_vpc ? 0 : 1
  vpc_id     = var.vpc_id
  cidr_block = var.vpc-cidr-block

  tags = merge(var.tags, {
    "Name"        = "${var.environment_prefix}-vertica-nodes"
    "subnet-role" = "vertica-nodes"
  })
}

resource "aws_route_table" "vertica_route" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = var.vpc_id
  tags   = var.tags
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_id
  }
}

resource "aws_route_table_association" "vertica_route_to_subnet" {
  count          = var.use_existing_vpc ? 0 : 1
  route_table_id = aws_route_table.vertica_route[0].id
  subnet_id      = aws_subnet.vertica_subnet[0].id
}

resource "random_string" "random" {
  count = var.vertica-mode == "Eon Mode" ? 1 : 0
  length           = 16
  special          = false
  upper            = false
}

resource "aws_s3_bucket" "s3_bucket" {
  count = var.vertica-mode == "Eon Mode" ? 1 : 0
  bucket = "${var.environment_prefix}-${random_string.random[0].id}-s3"
  force_destroy = true
  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_access" {
  count = var.vertica-mode == "Eon Mode" ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket[0].id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning_s3" {
  count = (var.vertica-mode == "Eon Mode" && var.enable_s3_versioning) ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_encryption" {
  count = var.vertica-mode == "Eon Mode" ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_iam_role" "s3_full_access_role" {
  count = var.vertica-mode == "Eon Mode" ? 1 : 0
  name = "${var.environment_prefix}-s3_full_access_role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_policy" "s3_full_access_policy" {
  count = var.vertica-mode == "Eon Mode" ? 1 : 0
  name        = "${var.environment_prefix}-s3_full_access_policy"
  description = "Provides full access to S3 buckets"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_full_access_attachment" {
  count = var.vertica-mode == "Eon Mode" ? 1 : 0
  role       = aws_iam_role.s3_full_access_role[0].name
  policy_arn = aws_iam_policy.s3_full_access_policy[0].arn
}

resource "aws_iam_instance_profile" "vertica_profile" {
  count = var.vertica-mode == "Eon Mode" ? 1 : 0
  name = "${var.environment_prefix}-vertica-profile"
  role = aws_iam_role.s3_full_access_role[0].name
}

resource "aws_instance" "vertica_node" {
  associate_public_ip_address = false
  count         = var.vertica_node_count
  ami           = local.ami-id
  instance_type = var.vertica_node_instance_type

  subnet_id     = var.use_existing_vpc ? var.existing_private_vertica_subnet_id: aws_subnet.vertica_subnet[0].id
  vpc_security_group_ids = [aws_security_group.vertica_sg.id]
  key_name      = var.ssh_keypair_name
  ebs_optimized = true
  user_data = <<-EOF
              #!/bin/bash
              % if var.vertica_username != "dbadmin" %
                sudo adduser ${var.vertica_username}
                sudo passwd -l ${var.vertica_username}
                sudo usermod -aG wheel ${var.vertica_username}
                echo '${var.vertica_username} ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/${var.vertica_username}
                sudo su - ${var.vertica_username} << 'EOSU'
                mkdir -p ~/.ssh
                chmod 700 ~/.ssh
                echo "${var.ssh_public_key}" > ~/.ssh/authorized_keys
                chmod 600 ~/.ssh/authorized_keys
                EOSU
              % endif %
              EOF
  root_block_device {
    encrypted             = true
    delete_on_termination = true
    volume_type           = var.vertica_node_root_block_volume_type
  }

  ebs_block_device {
    device_name           = "/dev/sdf"   # Adjust device name as needed
    volume_type           = var.vertica12-node-catalog-volume-type        # Adjust volume type as needed
    volume_size           = var.vertica_node_catalog_volume_size          # Adjust volume size as needed
    iops                  = var.vertica_node_catalog_volume_iops
    delete_on_termination = true         # Adjust delete on termination as needed
  }

  ebs_block_device {
    device_name           = "/dev/sdg"   # Adjust device name as needed
    volume_type           = var.vertica12-node-temp-volume-type        # Adjust volume type as needed
    volume_size           = var.vertica_node_temp_volume_size          # Adjust volume size as needed
    iops                  = var.vertica_node_temp_volume_iops
    delete_on_termination = true         # Adjust delete on termination as needed
  }

  dynamic "ebs_block_device" {
    for_each = range(8)
    content {
      device_name           = "/dev/sd${element(["h", "i", "j", "k", "l", "m", "n", "o"], ebs_block_device.key)}"    # Adjust device name as needed
      volume_type           = var.vertica12-node-data-volume-type        # Adjust volume type as needed
      volume_size           = var.vertica_node_data_volume_size          # Adjust volume size as needed
      iops                  = var.vertica_node_data_volume_iops
      delete_on_termination = true         # Adjust delete on termination as needed
    }
  }

  iam_instance_profile = var.vertica-mode == "Eon Mode" ? aws_iam_instance_profile.vertica_profile[0].name : null
  tags = merge(var.tags, {
    "Role" = "vertica"
    "Name" = "${var.environment_prefix}-vertica-nodes${count.index}"
  })
}

resource "aws_security_group" "vertica_sg" {
  name   = "${var.environment_prefix}-vertica-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment_prefix}-vertica-sg"
  })
}

resource "null_resource" "install_vertica" {
  depends_on = [aws_instance.vertica_node]
  provisioner "file" {
    connection {
      host        = var.bastion_public_ip
      type        = local.remote_login_type
      user        = local.bastion_username
      timeout     = local.remote_login_timeout
      private_key = var.ssh_private_key
      agent       = false
    }
    content = templatefile("${path.module}/install_vertica.tpl",
      {
        vertica_hosts         = join(",", aws_instance.vertica_node[*].private_ip),
        vertica_host_ips      = join(" ", aws_instance.vertica_node.*.private_ip),
        vertica_host_ip       = aws_instance.vertica_node[0].private_ip
        vertica_dba_user      = var.vertica_username,
        vertica_dba_group     = var.vertica_dba_group
        vertica_dba_password  = var.vertica_password,
        vertica_license_file  = var.vertica_license_file,
        vertica_database_name = var.vertica_database_name,
        vertica_ro_username   = var.vertica_ro_username,
        vertica_ro_password   = var.vertica_ro_password,
        vertica_rw_username   = var.vertica_rw_username,
        vertica_rw_password   = var.vertica_rw_password,
        pulsar_udx_file       = join(",",var.pulsar_udx_file)
        skip_dbinit           = var.skip_dbinit
        multi_tenancy         = var.multi_tenancy
        vertica-mode          = var.vertica-mode
        vertica_shard_count   = var.vertica_shard_count
        vertica_timezone      = var.vertica_timezone
        communal_location_url = var.vertica-mode == "Eon Mode" ? "s3://${aws_s3_bucket.s3_bucket[0].id}/vertica-eon" : ""
        vertica_node_data_volume_size = var.vertica_node_data_volume_size
    })
    destination = "/home/${var.bastion-username}/system-setup/install_vertica.sh"
  }

  provisioner "local-exec" {
    command = "chmod 400 ${path.cwd}/${var.ssh_private_key_file}; ssh-add -k ${path.cwd}/${var.ssh_private_key_file}"
  }
}

resource "null_resource" "install_vertica_rpm" {
  depends_on = [null_resource.install_vertica]
  provisioner "remote-exec" {
    connection {
      host        = var.bastion_public_ip
      type        = local.remote_login_type
      user        = local.bastion_username
      timeout     = local.remote_login_timeout
      private_key = var.ssh_private_key
      agent       = true
    }
    inline = [
      "chmod +x ~/system-setup/install_vertica.sh",
      "set -o pipefail",
      "~/system-setup/install_vertica.sh | tee ~/system-setup/install_vertica.log"
    ]

  }
}

resource "aws_cloudformation_stack" "vertica_mc_stack" {
  count         = var.vertica_mc_for_monitoring ? 1 : 0
  name          = local.name
  template_body = file("${path.module}/../vertica-mc/vertica-mc.template")
  capabilities  = ["CAPABILITY_NAMED_IAM"]
  tags          = var.tags
  parameters = {
    ExistingVPC       = var.vpc_id
    KeyName           = var.ssh_keypair_name
    ExistingSubnet    = var.public_subnet_id
    McDbadmin         = var.vertica_mc_db_admin
    McDbadminPassword = var.vertica_mc_db_admin_password
    MCInstanceType    = var.vertica_mc_instance_type
    AWSAuthenticate   = var.vertica_mc_aws_authenticate
    SSHLocation       = var.vertica_mc_cidr_block
    EULA              = local.vertica_mc_eula
    CustomAmi         = local.ami-id
  }
}

data "aws_region" "current" {}

locals {
  #vertica_mc_url  = element(split(",", one(aws_cloudformation_stack.vertica_mc_stack[*].outputs["ManagementConsole"])), 0)
  vertica_mc_url  = var.vertica_mc_for_monitoring ? element(split(",", aws_cloudformation_stack.vertica_mc_stack[0].outputs["ManagementConsole"]), 0) : ""
  url_parts       = regex("^(?:[^:/?#]+:)?(?://(?P<hostname>[^/?#]*):(?P<port>\\d+))?", local.vertica_mc_url)
  vertica_mc_port = local.url_parts["port"]
}

resource "null_resource" "vertica_mc_cluster_private_ip" {
  count         = var.vertica_mc_for_monitoring ? 1 : 0
  depends_on = [aws_cloudformation_stack.vertica_mc_stack]
  provisioner "local-exec" {
    command = "aws ec2 --region ${data.aws_region.current.name} describe-instances --filters Name=vpc-id,Values=${var.vpc_id} --query 'Reservations[*].Instances[?Tags[?Value==`${var.environment_prefix}-vertica-mc-stack Vertica Management Console`]].PrivateIpAddress' --output text > ${data.template_file.vertica_mc_cluster_ip[0].rendered}"
  }
}

data "template_file" "vertica_mc_cluster_ip" {
  count         = var.vertica_mc_for_monitoring ? 1 : 0
  template = "${path.module}/vetica_mc.log"
}

data "local_file" "vertica_mc_cluster_ip" {
  count         = var.vertica_mc_for_monitoring ? 1 : 0
  depends_on = [null_resource.vertica_mc_cluster_private_ip]
  filename   = data.template_file.vertica_mc_cluster_ip[0].rendered
}

resource "null_resource" "vertica_cluster_ips" {
  count         = var.vertica_mc_for_monitoring ? 1 : 0
  provisioner "local-exec" {
    command = "aws ec2 --region ${data.aws_region.current.name} describe-instances --filters Name=vpc-id,Values=${var.vpc_id} --query \"Reservations[].Instances[?Tags[?Value=='${var.environment_prefix}-vertica-db']].PrivateIpAddress\" --output text > ${data.template_file.vertica_cluster_ips[0].rendered}"
  }
}

data "template_file" "vertica_cluster_ips" {
  count         = var.vertica_mc_for_monitoring ? 1 : 0
  template = "${path.module}/vertica_nodes.log"
}

data "local_file" "vertica_cluster_ips" {
  count         = var.vertica_mc_for_monitoring ? 1 : 0
  depends_on = [null_resource.vertica_cluster_ips]
  filename   = data.template_file.vertica_cluster_ips[0].rendered
}
