locals {
  oracle-client-path = "~/system-setup/oracle-client"
}

resource "null_resource" "oracle-instant-client" {

  depends_on = [null_resource.bastion-directories, null_resource.packages]

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
      "mkdir ${local.oracle-client-path}",
      "wget ${var.oracle-instantclient-rpm-repo} -P ${local.oracle-client-path}",
      "wget ${var.oracle-sqlplus-rpm-repo} -P ${local.oracle-client-path}",
      "sudo yum install -y ${local.oracle-client-path}/*.rpm | tee ~/system-setup/oracle-client/install_oracleclient.log"
    ]
  }
}