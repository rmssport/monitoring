output "vm_id" {
  description = "Proxmox VM ID"
  value       = proxmox_virtual_environment_vm.monitoring.vm_id
}

output "vm_ip" {
  description = "VM IP address"
  value       = var.vm_ip
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh ${var.vm_user}@${split("/", var.vm_ip)[0]}"
}

output "librenms_url" {
  description = "LibreNMS web UI URL (available after Ansible provisioning)"
  value       = "http://${split("/", var.vm_ip)[0]}:8000"
}
