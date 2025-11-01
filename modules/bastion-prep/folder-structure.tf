resource "null_resource" "bastion-directories" {
  provisioner "remote-exec" {
    connection {
      host = var.bastion-public-ip
      type = "ssh"
      user = var.bastion-username
      timeout = "10m"
      private_key = var.ssh-private-key
      agent = false
    }
    inline = [
      "mkdir ~/bin",
      "mkdir ~/system-setup"
    ]
  }
}