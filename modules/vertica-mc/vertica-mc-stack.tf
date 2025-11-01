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

resource "aws_cloudformation_stack" "vertica_mc_stack" {
  name          = local.name
  template_body = file("${path.module}/vertica-mc.template")
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
  vertica_mc_url  = element(split(",", aws_cloudformation_stack.vertica_mc_stack.outputs["ManagementConsole"]), 0)
  url_parts       = regex("^(?:[^:/?#]+:)?(?://(?P<hostname>[^/?#]*):(?P<port>\\d+))?", local.vertica_mc_url)
  vertica_mc_port = local.url_parts["port"]
}

resource "null_resource" "vertica_mc_cluster_private_ip" {
  depends_on = [aws_cloudformation_stack.vertica_mc_stack]
  provisioner "local-exec" {
    command = "aws ec2 --region ${data.aws_region.current.name} describe-instances --filters Name=vpc-id,Values=${var.vpc_id} --query 'Reservations[*].Instances[?Tags[?Value==`${var.environment_prefix}-vertica-mc-stack Vertica Management Console`]].PrivateIpAddress' --output text > ${data.template_file.vertica_mc_cluster_ip.rendered}"
  }
}

data "template_file" "vertica_mc_cluster_ip" {
  template = "${path.module}/vertica_mc.log"
}

data "local_file" "vertica_mc_cluster_ip" {
  depends_on = [null_resource.vertica_mc_cluster_private_ip]
  filename   = data.template_file.vertica_mc_cluster_ip.rendered
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

resource "null_resource" "prepare_vertica_provisioning" {
  depends_on = [aws_cloudformation_stack.vertica_mc_stack, aws_subnet.vertica_subnet, aws_s3_bucket.s3_bucket, aws_s3_bucket_public_access_block.s3_bucket_access]

  provisioner "file" {
    connection {
      host        = var.bastion_public_ip
      type        = local.remote_login_type
      user        = local.bastion_username
      timeout     = local.remote_login_timeout
      private_key = var.ssh_private_key
      agent       = false
    }
    content = templatefile("${path.module}/provision_vertica_cluster.tpl",
      {
        environment_prefix               = var.environment_prefix,
        vertica_mc_ip                    = trimspace(data.local_file.vertica_mc_cluster_ip.content),
        vertica_mc_port                  = local.vertica_mc_port,
        vertica_mc_db_admin              = var.vertica_mc_db_admin,
        vertica_mc_db_admin_password     = var.vertica_mc_db_admin_password,
        aws_region                       = data.aws_region.current.name,
        aws_key_pair                     = var.ssh_keypair_name,
        aws_cidr_range                   = var.vertica_cluster_ssh_location,
        vertica_database_name            = var.vertica_database_name,
        vertica_username                 = var.vertica_username,
        vertica_password                 = var.vertica_password,
        number_of_nodes                  = var.vertica_node_count,
        subnet_id                        = var.use_existing_vpc ? var.existing_private_vertica_subnet_id: aws_subnet.vertica_subnet[0].id,
        aws_instance_type                = var.vertica_node_instance_type,
        custom_ami                       = local.ami-id,
        node_ip_setting                  = var.vertica_node_ip_setting,
        deployment-id                    = var.deployment-id,
        vertica_license_file             = var.vertica_license_file,
        vertica_node_data_volume_type    = var.vertica_node_data_volume_type,
        vertica_node_data_volume_size    = var.vertica_node_data_volume_size,
        vertica_node_data_volume_iops    = var.vertica_node_data_volume_iops,
        vertica_node_catalog_volume_type = var.vertica_node_catalog_volume_type,
        vertica_node_catalog_volume_size = var.vertica_node_catalog_volume_size,
        vertica_node_catalog_volume_iops = var.vertica_node_catalog_volume_iops,
        vertica_node_temp_volume_type    = var.vertica_node_temp_volume_type,
        vertica_node_temp_volume_size    = var.vertica_node_temp_volume_size,
        vertica_node_temp_volume_iops    = var.vertica_node_temp_volume_iops,
        vertica-mode                     = var.vertica-mode,
        eon_mode_string                  = var.vertica-mode == "Eon Mode" ? "true" : "false",
        communal_location_url            = var.vertica-mode == "Eon Mode" ? "s3://${aws_s3_bucket.s3_bucket[0].id}/vertica-eon" : ""
    })
    destination = "/home/${var.bastion-username}/system-setup/provision_vertica_cluster.sh"
  }

  provisioner "file" {
    connection {
      host        = var.bastion_public_ip
      type        = local.remote_login_type
      user        = local.bastion_username
      timeout     = local.remote_login_timeout
      private_key = var.ssh_private_key
      agent       = false
    }
    content = templatefile("${path.module}/destroy_vertica_cluster.tpl",
      {
        environment_prefix = var.environment_prefix,
        vpc_id             = var.vpc_id,
        aws_key_pair       = var.ssh_keypair_name,
        aws_region         = data.aws_region.current.name
    })
    destination = "/home/${var.bastion-username}/system-setup/destroy_vertica_cluster.sh"
  }
}

resource "null_resource" "provision_vertica_db" {
  depends_on = [null_resource.prepare_vertica_provisioning]

  provisioner "remote-exec" {
    connection {
      host        = var.bastion_public_ip
      type        = local.remote_login_type
      user        = local.bastion_username
      timeout     = local.remote_login_timeout
      private_key = var.ssh_private_key
      agent       = false
    }
    inline = [
      "chmod +x ~/system-setup/provision_vertica_cluster.sh",
      "~/system-setup/provision_vertica_cluster.sh | tee ~/system-setup/provision_vertica_cluster.log"
    ]
  }

  triggers = {
    connection_host        = var.bastion_public_ip
    connection_type        = local.remote_login_type
    connection_user        = local.bastion_username
    connection_timeout     = local.remote_login_timeout
    connection_private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    when = destroy
    connection {
      host        = self.triggers.connection_host
      type        = self.triggers.connection_type
      user        = self.triggers.connection_user
      timeout     = self.triggers.connection_timeout
      private_key = self.triggers.connection_private_key
      agent       = false
    }
    inline = [
      "chmod +x ~/system-setup/destroy_vertica_cluster.sh",
      "~/system-setup/destroy_vertica_cluster.sh | tee ~/system-setup/destroy_vertica_cluster.log"
    ]
  }
}

resource "null_resource" "vertica_cluster_ips" {
  depends_on = [null_resource.provision_vertica_db]
  provisioner "local-exec" {
    command = "aws ec2 --region ${data.aws_region.current.name} describe-instances --filters Name=vpc-id,Values=${var.vpc_id} --query \"Reservations[].Instances[?Tags[?Value=='${var.environment_prefix}-vertica-db']].PrivateIpAddress\" --output text > ${data.template_file.vertica_cluster_ips.rendered}"
  }
}

data "template_file" "vertica_cluster_ips" {
  template = "${path.module}/vertica_nodes.log"
}

data "local_file" "vertica_cluster_ips" {
  depends_on = [null_resource.vertica_cluster_ips]
  filename   = data.template_file.vertica_cluster_ips.rendered
}

resource "null_resource" "prepare_pulsar_udx" {
  depends_on = [null_resource.provision_vertica_db]

  provisioner "file" {
    connection {
      host        = var.bastion_public_ip
      type        = local.remote_login_type
      user        = local.bastion_username
      timeout     = local.remote_login_timeout
      private_key = var.ssh_private_key
      agent       = false
    }
    content = templatefile("${path.module}/setup_pulsar_udx.tpl",
      {
        environment_prefix    = var.environment_prefix,
        vpc_id                = var.vpc_id,
        aws_region            = data.aws_region.current.name,
        vertica_database_name = var.vertica_database_name,
        vertica_username      = var.vertica_username,
        vertica_password      = var.vertica_password,
        vertica_ro_username   = var.vertica_ro_username,
        vertica_ro_password   = var.vertica_ro_password,
        vertica_rw_username   = var.vertica_rw_username,
        vertica_rw_password   = var.vertica_rw_password,
        pulsar_udx_file       = join(",",var.pulsar_udx_file)
        skip_dbinit           = var.skip_dbinit
    })
    destination = "/home/${var.bastion-username}/system-setup/setup_pulsar_udx.sh"
  }

  provisioner "local-exec" {
    command = "chmod 400 ${path.cwd}/${var.ssh_private_key_file}; ssh-add -k ${path.cwd}/${var.ssh_private_key_file}"
  }
}

resource "null_resource" "setup_pulsar_udx" {
  depends_on = [null_resource.prepare_pulsar_udx]

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
      "chmod +x ~/system-setup/setup_pulsar_udx.sh",
      "set -o pipefail ; ~/system-setup/setup_pulsar_udx.sh | tee ~/system-setup/setup_pulsar_udx.log"
    ]
  }
}
