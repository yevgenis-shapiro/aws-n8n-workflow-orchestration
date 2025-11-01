locals {
  postgres-client-version = var.database-engine == "postgres" ? split(".", var.database-engine-version)[0] : "14"
  postgres                = "postgresql${local.postgres-client-version}"
}

resource "null_resource" "postgres-client" {
  depends_on = [null_resource.bastion-directories]

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
      "sudo amazon-linux-extras install -y postgresql14 | tee ~/system-setup/install_postgressql.log"
    ]
  }
}

/* Hardcoding postgres version 14 because amazon-linux-extras does not support postgres15 client yet and has not 
specific date to add. Will update in future to keep postgres client version same as server. */
