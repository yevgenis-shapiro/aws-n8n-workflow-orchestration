resource "null_resource" "suite-cert" {
  count = length(var.load-balancer-certificate-data)

  depends_on = [null_resource.bastion-directories]

  provisioner "file" {
    content     = var.load-balancer-certificate-data[0]
    destination = "/home/${var.bastion-username}/system-setup/itom-lb.pem"

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
    content     = var.load-balancer-ca-certificate-data[0]
    destination = "/home/${var.bastion-username}/system-setup/itom-lb-ca.pem"

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
      "sudo cp ~/system-setup/itom-lb.pem /etc/pki/ca-trust/source/anchors/itom-lb.pem",
      "sudo cp ~/system-setup/itom-lb-ca.pem /etc/pki/ca-trust/source/anchors/itom-lb-ca.pem",
      "sudo update-ca-trust extract"
    ]
  }
}