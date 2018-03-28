terraform {
  required_version = ">= 0.10.0"
}

data "azurerm_resource_group" "vault" {
  name = "${var.resource_group_name}"
}

data "template_file" "consul" {
  count    = "${var.cluster_size}"
  template = "${file("${path.module}/files/consul-config-json")} "

  vars {
    location              = "${var.location}"
    consul_client_name    = "${format("${var.vault_computer_name_prefix}-%02d", 1 + count.index)}"
    consul_join_addresses = "${jsonencode(var.consul_cluster_addresses)}"
    http_port             = "${var.consul_http_api_port}"
    consul_install_path   = "${var.consul_install_path}"
    tls_key_file_path     = "${var.consul_tls_key_file_path}"
    tls_cert_file_path    = "${var.consul_tls_cert_file_path}"
    tls_ca_file_path      = "${var.consul_tls_ca_file_path}"
    gossip_encryption_key = "${var.gossip_encryption_key}"
  }
}

data "template_file" "vault" {
  count    = "${var.cluster_size}"
  template = "${file("${path.module}/files/vault-config-hcl")}"

  vars {
    instance_ip_address       = "${azurerm_network_interface.vault.*.private_ip_address[count.index]}"
    port                      = "${var.api_port}"
    cluster_port              = "${var.cluster_port}"
    consul_tls_key_file_path  = "${var.consul_tls_key_file_path}"
    consul_tls_cert_file_path = "${var.consul_tls_cert_file_path}"
    consul_tls_ca_file_path   = "${var.consul_tls_ca_file_path}"
    vault_tls_cert_file_path  = "${var.vault_tls_cert_file_path}"
    vault_tls_key_file_path   = "${var.vault_tls_key_file_path}"
  }
}

data "template_file" "custom_data_vault" {
  count    = "${var.cluster_size}"
  template = "${file("${path.module}/files/vault-run-sh")}"

  vars {
    consul_config = "${data.template_file.consul.*.rendered[count.index]}"
    vault_config  = "${data.template_file.vault.*.rendered[count.index]}"
  }
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE NETWORK INTERFACES TO RUN VAULT
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_network_interface" "vault" {
  count               = "${var.cluster_size}"
  name                = "${format("${var.vault_computer_name_prefix}-%02d", 1 + count.index)}"
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.vault.name}"

  ip_configuration {
    name                          = "${format("${var.vault_computer_name_prefix}-%02d", 1 + count.index)}"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"
  }
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE VIRTUAL MACHINES TO RUN VAULT
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_machine" "vault" {
  count                            = "${var.cluster_size}"
  name                             = "${format("${var.vault_computer_name_prefix}-%02d", 1 + count.index)}"
  location                         = "${var.location}"
  resource_group_name              = "${data.azurerm_resource_group.vault.name}"
  network_interface_ids            = ["${azurerm_network_interface.vault.*.id[count.index]}"]
  vm_size                          = "${var.instance_size}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = "${var.image_id}"
  }

  storage_os_disk {
    name              = "${format("${var.vault_computer_name_prefix}-%02d-os-disk", 1 + count.index)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    os_type           = "Linux"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${format("${var.vault_computer_name_prefix}-%02d", 1 + count.index)}"
    admin_username = "${var.admin_user_name}"
    admin_password = "${uuid()}"
    custom_data    = "${data.template_file.custom_data_vault.*.rendered[count.index]}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_user_name}/.ssh/authorized_keys"
      key_data = "${var.key_data}"
    }
  }

  lifecycle {
    ignore_changes = ["admin_password"]
  }
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP AND RULES FOR SSH
# ---------------------------------------------------------------------------------------------------------------------


# resource "azurerm_network_security_group" "vault" {
#   name                = "${var.cluster_name}"
#   location            = "${var.location}"
#   resource_group_name = "${data.azurerm_resource_group.vault.name}"
# }


# resource "azurerm_network_security_rule" "ssh" {
#   count = "${length(var.allowed_ssh_cidr_blocks)}"


#   access                      = "Allow"
#   destination_address_prefix  = "*"
#   destination_port_range      = "22"
#   direction                   = "Inbound"
#   name                        = "SSH${count.index}"
#   network_security_group_name = "${azurerm_network_security_group.vault.name}"
#   priority                    = "${100 + count.index}"
#   protocol                    = "Tcp"
#   resource_group_name         = "${data.azurerm_resource_group.vault.name}"
#   source_address_prefix       = "${element(var.allowed_ssh_cidr_blocks, count.index)}"
#   source_port_range           = "*"
# }

