output "nfs-ips" {
  value = aws_efs_mount_target.itom-nfs-mount-targets[*].ip_address
}

output "nfs-dns-names" {
  value = aws_efs_mount_target.itom-nfs-mount-targets[*].dns_name
}

output "nfs-dns-name" {
  value = aws_efs_file_system.itom-nfs.dns_name
}

output "efs-arn" {
  value = aws_efs_file_system.itom-nfs.arn
}