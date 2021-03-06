# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "location" {
  description = "The location that the resources will run in (e.g. East US)"
}

variable "resource_group_name" {
  description = "The name of the resource group that the resources for consul will run in"
}

variable "subnet_id" {
  description = "The id of the subnet to deploy the cluster into"
}

variable "cluster_name" {
  description = "The name of the Consul cluster (e.g. consul-stage). This variable is used to namespace all resources created by this module."
}

variable "image_id" {
  description = "The URL of the Image to run in this cluster. Should be an image that had Consul installed and configured by the install-consul module."
}

variable "instance_size" {
  description = "The size of Azure Instances to run for each node in the cluster (e.g. Standard_A0)."
}

variable "key_data" {
  description = "The SSH public key that will be added to SSH authorized_users on the consul instances"
}

variable "gossip_encryption_key" {
  description = "The encryption key for consul to encrypt gossip traffic"
}

variable "consul_cluster_addresses" {
  description = "Addresses* of consul servers in cluster to join."
  type        = "list"
}

variable "vault_tls_cert_file_path" {
  description = "Specifies the path to the certificate for TLS. Required. To use a CA certificate, concatenate the primary certificate and the CA certificate together."
}

variable "vault_tls_key_file_path" {
  description = "Specifies the path to the private key for the certificate."
}

variable "consul_tls_cert_file_path" {
  description = "Specifies the path to the certificate for TLS."
}

variable "consul_tls_key_file_path" {
  description = "Specifies the path to the certificate for TLS."
}

variable "consul_tls_ca_file_path" {
  description = "Specifies the path to the certificate for TLS."
}

variable "consul_install_path" {
  description = "Path where consul is installed"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "instance_tier" {
  description = "Specifies the tier of virtual machines in a scale set. Possible values, standard or basic."
  default     = "standard"
}

variable "consul_computer_name_prefix" {
  description = "The string that the name of each instance in the cluster will be prefixed with"
  default     = "consul"
}

variable "vault_computer_name_prefix" {
  description = "The string that the name of each instance in the cluster will be prefixed with"
  default     = "vault"
}

variable "admin_user_name" {
  description = "The name of the administrator user for each instance in the cluster"
  default     = "vaultadmin"
}

variable "instance_root_volume_size" {
  description = "Specifies the size of the instance root volume in GB. Default 40GB"
  default     = 40
}

variable "cluster_size" {
  description = "The number of nodes to have in the Consul cluster. We strongly recommended that you use either 3 or 5."
  default     = 3
}

variable "cluster_tag_key" {
  description = "Add a tag with this key and the value var.cluster_tag_value to each Instance in the ASG. This can be used to automatically find other Consul nodes and form a cluster."
  default     = "consul-servers"
}

variable "cluster_tag_value" {
  description = "Add a tag with key var.clsuter_tag_key and this value to each Instance in the ASG. This can be used to automatically find other Consul nodes and form a cluster."
  default     = "auto-join"
}

variable "subnet_ids" {
  description = "The subnet IDs into which the Azure Instances should be deployed. We recommend one subnet ID per node in the cluster_size variable. At least one of var.subnet_ids or var.availability_zones must be non-empty."
  type        = "list"
  default     = []
}

variable "allowed_ssh_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the Azure Instances will allow SSH connections"
  type        = "list"
  default     = []
}

variable "root_volume_type" {
  description = "The type of volume. Must be one of: standard, gp2, or io1."
  default     = "standard"
}

variable "root_volume_size" {
  description = "The size, in GB, of the root EBS volume."
  default     = 50
}

variable "root_volume_delete_on_termination" {
  description = "Whether the volume should be destroyed on instance termination."
  default     = true
}

variable "api_port" {
  description = "The port to use for Vault API calls. Vault default is 8200"
  default     = 8200
}

variable "cluster_port" {
  description = "The port to use for Vault cluster server-to-server requests. Vault default is 8201"
  default     = 8201
}

variable "consul_http_api_port" {
  description = "The port used by consul http api.  Consul default is 8500."
  default     = 8500
}

variable "tags" {
  type        = "map"
  description = "A map of the tags to use on the resources that are deployed with this module."
  default     = {}
}
