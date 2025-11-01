locals {
  kubectl_checksum_download_location = "${var.kubectl_download_location}.sha256"
}

resource "null_resource" "kubernetes-client" {

  depends_on = [null_resource.bastion-directories, null_resource.awscli]

  provisioner "file" {
    content = templatefile("${path.module}/install_configure_kubernetes_client.tpl",
      {
        kubectl_download_location          = var.kubectl_download_location,
        kubectl_checksum_download_location = local.kubectl_checksum_download_location,
        eks_cluster_name                   = var.eks_cluster_name
        eks_cluster_region                 = var.eks_cluster_region
    })
    destination = "/home/${var.bastion-username}/system-setup/install_configure_kubernetes_client.sh"

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
      "chmod +x ~/system-setup/install_configure_kubernetes_client.sh",
      "~/system-setup/install_configure_kubernetes_client.sh | tee ~/system-setup/install_configure_kubernetes_client.log"
    ]
  }
}
