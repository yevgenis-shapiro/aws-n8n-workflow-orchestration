resource "null_resource" "helm-client" {

  depends_on = [null_resource.kubernetes-client]

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
      "curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > ~/system-setup/get_helm.sh",
      "chmod 700 ~/system-setup/get_helm.sh",
      "~/system-setup/get_helm.sh ${var.helm-version != "" ? "--version ${var.helm-version}" : ""}"
    ]
  }
}

resource "null_resource" "helm_version" {

  triggers = {
    always_run = "${timestamp()}"
  }
  depends_on = [null_resource.helm-client]

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
      "helm version > /tmp/helm_version.txt"
    ]
  }
}

