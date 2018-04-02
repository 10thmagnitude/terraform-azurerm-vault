output "cluster_ip_addresses" {
  value = "${azurerm_network_interface.vault.*.private_ip_address}"
}
