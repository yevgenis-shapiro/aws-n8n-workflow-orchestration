output "helm_version" {
  description = "The Helm version captured from the remote host."
  value       = null_resource.helm_version.triggers["always_run"]
}
