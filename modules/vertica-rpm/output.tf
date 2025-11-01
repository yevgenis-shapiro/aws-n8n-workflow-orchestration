output "vertica_cluster_private_ips" {
  value = aws_instance.vertica_node[*].private_ip
}

output "vertica_management_console" {
  value = length(data.local_file.vertica_mc_cluster_ip) > 0 ? "https://${trimspace(data.local_file.vertica_mc_cluster_ip[0].content)}:${local.vertica_mc_port}/webui" : null
}

output "vertica_management_console_ssh" {
  value = length(data.local_file.vertica_mc_cluster_ip) > 0 ? "ssh -i ${var.ssh_private_key_file} ${var.vertica_mc_db_admin}@${trimspace(data.local_file.vertica_mc_cluster_ip[0].content)}" : null
}

output "vertica_cluster_ip_address" {
  value = length(data.local_file.vertica_cluster_ips) > 0 ? data.local_file.vertica_cluster_ips[0].content : null
}
