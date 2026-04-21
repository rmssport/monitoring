resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = var.snippets_datastore
  node_name    = var.proxmox_node

  source_raw {
    data = templatefile("${path.module}/cloud-init/user-data.yml", {
      hostname    = var.vm_name
      user        = var.vm_user
      ssh_key     = var.ssh_public_key
      repo_url    = var.monitoring_repo_url
      repo_branch = var.monitoring_repo_branch
    })
    file_name = "${var.vm_name}-user-data.yml"
  }
}

resource "proxmox_virtual_environment_vm" "monitoring" {
  name      = var.vm_name
  node_name = var.proxmox_node
  vm_id     = var.vm_id > 0 ? var.vm_id : null

  clone {
    vm_id        = var.template_vm_id
    datastore_id = var.datastore
    full         = true
  }

  cpu {
    cores   = var.vm_cores
    sockets = 1
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.vm_memory
  }

  disk {
    interface    = "scsi0"
    datastore_id = var.datastore
    size         = var.vm_disk_size
    discard      = "on"
  }

  network_device {
    bridge  = var.network_bridge
    model   = "virtio"
    vlan_id = var.vlan_id
  }

  initialization {
    datastore_id = var.snippets_datastore
    interface    = "ide2"

    ip_config {
      ipv4 {
        address = var.vm_ip
        gateway = var.vm_gateway
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
  }

  agent {
    enabled = true
  }

  on_boot = true

  lifecycle {
    ignore_changes = [
      disk[0].size,
    ]
  }
}
