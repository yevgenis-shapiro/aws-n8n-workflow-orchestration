data "aws_region" "current-region" {}

resource "null_resource" "rds-certs" {

  depends_on = [null_resource.bastion-directories, null_resource.awscli]

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
      "/usr/bin/wget https://truststore.pki.rds.amazonaws.com/${data.aws_region.current-region.name}/${data.aws_region.current-region.name}-bundle.pem -P ~/system-setup/ | tee ~/system-setup/download_rds_certs.log"
    ]
  }
}
