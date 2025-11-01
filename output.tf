output "private-ssh-key" {
  value     = module.ssh-key-pair.key-pair-private-ssh-key
  sensitive = true
}

output "key-pair-filename" {
  value = module.ssh-key-pair.key-pair-filename
}

output "bastion-public-ip" {
  value = module.bastion.public-ip
}

output "bastion-fqdns" {
  value = module.bastion.fqdn
}

output "db-address" {
  value = "${module.database.db-hostname}:${module.database.db-port}"
}

output "db-username" {
  value = module.database.db-username
}

output "efs-dns-names" {
  value = module.efs.nfs-dns-name
}

output "vpc-id" {
  value = module.vpc.vpc-id
}
