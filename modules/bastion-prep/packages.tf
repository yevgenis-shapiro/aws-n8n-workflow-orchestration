resource "null_resource" "packages" {
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
      "sudo amazon-linux-extras enable epel",
      "sudo yum install -y epel-release",
      "sudo yum -y update",
      "sudo yum install wget jq unzip -y"
    ]
  }
}

resource "null_resource" "awscli" {
  depends_on = [null_resource.packages]
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
      "(",
      "  curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\"",
      "  /usr/bin/unzip awscliv2.zip",
      "  sudo ./aws/install -i /usr/aws-cli -b /usr/bin",
      ") | tee ~/system-setup/install_awscli.log"
    ]
  }
}
