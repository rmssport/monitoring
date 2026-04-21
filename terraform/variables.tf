variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL (e.g., https://10.0.0.1:8006/)"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token in format: user@realm!tokenname=uuid"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS certificate verification for Proxmox API"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name to deploy the VM on"
  type        = string
  default     = "pve"
}

variable "template_vm_id" {
  description = "VM ID of the Debian 12 cloud-init template in Proxmox"
  type        = number
}

variable "vm_name" {
  description = "Name for the monitoring VM"
  type        = string
  default     = "rms-monitoring"
}

variable "vm_id" {
  description = "VM ID to assign (0 = auto-assign)"
  type        = number
  default     = 0
}

variable "vm_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "RAM in MB"
  type        = number
  default     = 4096
}

variable "vm_disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 40
}

variable "datastore" {
  description = "Proxmox storage for VM disk (e.g., local-lvm)"
  type        = string
  default     = "local-lvm"
}

variable "snippets_datastore" {
  description = "Proxmox storage for cloud-init snippets (must support snippets content type)"
  type        = string
  default     = "local"
}

variable "network_bridge" {
  description = "Proxmox network bridge (e.g., vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "vlan_id" {
  description = "VLAN tag for the VM network interface (null = no VLAN)"
  type        = number
  default     = null
}

variable "vm_ip" {
  description = "Static IP address with CIDR for the VM (e.g., 10.7.5.100/24)"
  type        = string
}

variable "vm_gateway" {
  description = "Default gateway for the VM"
  type        = string
}

variable "dns_servers" {
  description = "DNS server addresses"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "vm_user" {
  description = "Default user created by cloud-init"
  type        = string
  default     = "rms"
}

variable "monitoring_repo_url" {
  description = "Git repository URL for the monitoring repo"
  type        = string
  default     = "https://github.com/rmssport/monitoring.git"
}

variable "monitoring_repo_branch" {
  description = "Git branch to clone"
  type        = string
  default     = "main"
}
