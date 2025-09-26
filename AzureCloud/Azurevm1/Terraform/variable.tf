variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "kml_rg_main-5780e57b35c44201"
}

variable "location" {
  description = "Azure location for resources"
  type        = string
  default     = "westus"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "myVM"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "azure_vm_key.pub"
}
