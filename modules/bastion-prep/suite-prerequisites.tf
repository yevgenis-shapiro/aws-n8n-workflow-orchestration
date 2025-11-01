resource "null_resource" "suite-prerequisites" {

  depends_on = [null_resource.bastion-directories]

  provisioner "file" {
    content = templatefile("${path.module}/create_suite_pv.tpl",
      {
        efs_dns = var.efs_dns
    })
    destination = "/home/${var.bastion-username}/system-setup/create_suite_pv.sh"

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
      timeout     = "1m"
      private_key = var.ssh-private-key
      agent       = false
    }
    inline = [
      "chmod +x ~/system-setup/create_suite_pv.sh"
    ]
  }
}
