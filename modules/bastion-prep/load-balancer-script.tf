data "aws_region" "current" {}

resource "null_resource" "load-balancer-script" {
  depends_on = [null_resource.bastion-directories, data.aws_region.current]

  provisioner "file" {
    content = templatefile("${path.module}/load-balancer.sh.tpl",
      {
        vpc_id             = var.vpc-id
        aws_region         = data.aws_region.current.name
        certificate_arn    = var.load-balancer-certificate-arn
        environment_prefix = var.environment-prefix
        public_subnet_ids  = var.public-subnet-ids
        load_balancer_access_addresses = join(", ",
          formatlist(
            "\\\"%s\\\"",
            flatten([var.allowed-client-cidrs, var.vpc-cidr-block, "${var.nat-gw-ip}/32"])
          )
        )
        hosted_zone = var.hosted-zone
    })
    destination = "/home/${var.bastion-username}/bin/load-balancers.sh"

    connection {
      host        = var.bastion-public-ip
      type        = "ssh"
      user        = var.bastion-username
      timeout     = "10m"
      private_key = var.ssh-private-key
      agent       = false
    }
  }

  provisioner "file" {
    source      = "${path.module}/rules_core.sh"
    destination = "/home/${var.bastion-username}/bin/rules_core.sh"

    connection {
      host        = var.bastion-public-ip
      type        = "ssh"
      user        = var.bastion-username
      timeout     = "10m"
      private_key = var.ssh-private-key
      agent       = false
    }
  }

  provisioner "file" {
    source      = "${path.module}/rules_nom.sh"
    destination = "/home/${var.bastion-username}/bin/rules_nom.sh"

    connection {
      host        = var.bastion-public-ip
      type        = "ssh"
      user        = var.bastion-username
      timeout     = "10m"
      private_key = var.ssh-private-key
      agent       = false
    }
  }

  provisioner "file" {
    source      = "${path.module}/rules_opsb.sh"
    destination = "/home/${var.bastion-username}/bin/rules_opsb.sh"

    connection {
      host        = var.bastion-public-ip
      type        = "ssh"
      user        = var.bastion-username
      timeout     = "10m"
      private_key = var.ssh-private-key
      agent       = false
    }
  }

  provisioner "file" {
    source      = "${path.module}/rules_op.sh"
    destination = "/home/${var.bastion-username}/bin/rules_op.sh"

    connection {
      host        = var.bastion-public-ip
      type        = "ssh"
      user        = var.bastion-username
      timeout     = "10m"
      private_key = var.ssh-private-key
      agent       = false
    }
  }

  provisioner "remote-exec" {
    connection {
      host        = var.bastion-public-ip
      type        = "ssh"
      user        = var.bastion-username
      timeout     = "10m"
      private_key = var.ssh-private-key
      agent       = false
    }
    inline = [
      "chmod +x ~/bin/load-balancers.sh"
    ]
  }
}
