output "consul_ip_addresses" {
  value = "${module.consul_servers.cluster_ip_addresses}"
}

output "vault_ip_addresses" {
  value = "${module.vault_servers.cluster_ip_addresses}"
}
