resource "tls_private_key" "ssh-private-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh_key_pair" {
  key_name   = "${var.environment-prefix}-ssh-key"
  public_key = tls_private_key.ssh-private-key.public_key_openssh

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "local_file" "private_key" {
  content = tls_private_key.ssh-private-key.private_key_pem
  filename = "${var.environment-prefix}-ssh-private-key.pem"
}