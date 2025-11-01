resource "null_resource" "efs-volume" {

  depends_on = [null_resource.bastion-directories]

  provisioner "file" {
    content = templatefile("${path.module}/mount_volume.tpl",
      {
        efs_dns = var.efs_dns
    })
    destination = "/home/${var.bastion-username}/system-setup/mount_volume.sh"

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
      "chmod +x ~/system-setup/mount_volume.sh",
      "~/system-setup/mount_volume.sh | tee ~/system-setup/mount_volume.log"
    ]
  }
}

resource "null_resource" "efs-create-volume" {

  depends_on = [null_resource.efs-volume]

  provisioner "file" {
    content = templatefile("${path.module}/create_volume.tpl",
      {
        efs_dns = var.efs_dns
    })
    destination = "/home/${var.bastion-username}/system-setup/create_volume.sh"

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
      "chmod +x ~/system-setup/create_volume.sh",
      "~/system-setup/create_volume.sh ${var.uid} ${var.gid} /var/vols/itom/core | tee ~/system-setup/create_volume.log",
      "~/system-setup/create_volume.sh ${var.uid} ${var.gid} /var/vols/itom/itom-logging-vol | tee ~/system-setup/create_volume.log"
    ]
  }
}