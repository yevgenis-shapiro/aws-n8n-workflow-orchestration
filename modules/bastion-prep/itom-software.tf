resource "null_resource" "itom-software" {
  provisioner "file" {
    source = var.itom-software-directory
    destination = "/home/${var.bastion-username}"

    connection {
      host = var.bastion-public-ip
      type = "ssh"
      user = var.bastion-username
      timeout = "10m"
      private_key = var.ssh-private-key
      agent = false
    }
  }
}
