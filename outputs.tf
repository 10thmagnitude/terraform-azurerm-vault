output "cluster_ip_addresses" {
  value = "${azurerm_network_interface.vault.*.private_ip_address}"
}

output "vault_ui_address" {
  value = "${azurerm_network_interface.vault.0.private_ip_address}"
}

output "vault_http_api_port" {
  value = "${var.api_port}"
}
