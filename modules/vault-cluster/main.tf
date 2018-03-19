terraform {
  required_version = ">= 0.10.0"
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE STORAGE BUCKET
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_container" "vault" {
  name                  = "${var.storage_container_name}"
  resource_group_name   = "${var.resource_group_name}"
  storage_account_name  = "${var.storage_account_name}"
  container_access_type = "private"
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE NETWORK INTERFACES TO RUN VAULT
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_network_interface" "vault" {
  count               = "${var.cluster_size}"
  name                = "${format("${var.vault_computer_name_prefix}-%02d", 1 + count.index)}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

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
  resource_group_name              = "${var.resource_group_name}"
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
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_user_name}/.ssh/authorized_keys"
      key_data = "${var.key_data}"
    }
  }

  ## TODO: consul service user/group should be consul/consul?
  provisioner "file" {
    source      = "${path.module}/files/consul-service"
    destination = "/tmp/consul.service.moveme"
  }

  ## TODO: check recursors property in consul config for external DNS??
  ## TODO: simplify consul configuration file, by grabbing username:
  # $(echo `hostname`)
  # $(ifconfig eth0 | grep 'inet' | cut -d: -f2 | awk '{ print $2}')

  provisioner "file" {
    content     = "${data.template_file.cfg.*.rendered[count.index]}"
    destination = "/tmp/config.json.moveme"
  }
  provisioner "file" {
    content     = "${file("${path.module}/files/consul-run")}"
    destination = "/tmp/consul-run.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/consul-run.sh",
      "sudo /bin/bash -c /tmp/consul-run.sh",
    ]
  }
  connection {
    user         = "${var.admin_user_name}"
    host         = "${azurerm_network_interface.consul.*.private_ip_address[count.index]}"
    private_key  = "${var.private_key_path}"
    bastion_host = "${var.bastion_host_address}"
  }
  lifecycle {
    ignore_changes = ["admin_password"]
  }
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP AND RULES FOR SSH
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_network_security_group" "vault" {
  name                = "${var.cluster_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_network_security_rule" "ssh" {
  count = "${length(var.allowed_ssh_cidr_blocks)}"

  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "22"
  direction                   = "Inbound"
  name                        = "SSH${count.index}"
  network_security_group_name = "${azurerm_network_security_group.vault.name}"
  priority                    = "${100 + count.index}"
  protocol                    = "Tcp"
  resource_group_name         = "${var.resource_group_name}"
  source_address_prefix       = "${element(var.allowed_ssh_cidr_blocks, count.index)}"
  source_port_range           = "1024-65535"
}
