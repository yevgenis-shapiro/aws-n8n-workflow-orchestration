output "vertica_management_console" {
  value = "https://${trimspace(data.local_file.vertica_mc_cluster_ip.content)}:${local.vertica_mc_port}/webui"
}

output "vertica_management_console_ssh" {
  value = "ssh -i ${var.ssh_private_key_file} ${var.vertica_mc_db_admin}@${trimspace(data.local_file.vertica_mc_cluster_ip.content)}"
}

output "vertica_cluster_ip_address" {
  value = data.local_file.vertica_cluster_ips.content
}