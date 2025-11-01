output "key-pair-name" {
  value = aws_key_pair.ssh_key_pair.key_name
}

output "key-pair-private-ssh-key" {
  value     = tls_private_key.ssh-private-key.private_key_pem
  sensitive = true
}

output "key-pair-filename" {
  value = local_file.private_key.filename
}
output "public_key" {
  value = tls_private_key.ssh-private-key.public_key_openssh
}