# Proxmox Setup: Debian 13 Cloud-Init Template

One-time setup on the Proxmox host (10.0.0.99). This creates a VM template that Terraform clones to create the monitoring VM.

**Important:** You need the **cloud image** (genericcloud qcow2), NOT the netinst ISO. The cloud image is a pre-installed disk image that cloud-init configures at first boot. The netinst ISO is an interactive installer and won't work with Terraform.

## Create the Template

SSH into the Proxmox host and run:

```bash
# Download Debian 13 cloud image (NOT the netinst ISO)
cd /var/lib/vz/template/iso
wget https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2

# Create a new VM (use ID 9000 or any free ID)
qm create 9000 --name "debian-13-cloud" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Import the cloud image as the VM's disk
qm importdisk 9000 debian-13-genericcloud-amd64.qcow2 local-lvm

# Attach the imported disk
qm set 9000 --scsihw virtio-scsi-single --scsi0 local-lvm:vm-9000-disk-0

# Add cloud-init drive
qm set 9000 --ide2 local-lvm:cloudinit

# Set boot order
qm set 9000 --boot order=scsi0

# Enable serial console (needed for cloud-init)
qm set 9000 --serial0 socket --vga serial0

# Enable QEMU guest agent
qm set 9000 --agent enabled=1

# Convert to template
qm template 9000
```

Note the template VM ID (9000 in this example) — you'll need it for `terraform.tfvars`.

## Verify

In the Proxmox web UI, you should see "debian-13-cloud" listed as a template under your node.

## API Token

Terraform needs an API token to manage VMs.

### Create the token

1. Open Proxmox web UI: `https://10.0.0.99:8006`
2. Go to **Datacenter** -> **Permissions** -> **API Tokens**
3. Click **Add**:
   - **User:** `root@pam` (or create a dedicated `terraform@pve` user)
   - **Token ID:** `monitoring`
   - **Privilege Separation:** unchecked (or assign roles below)
4. Copy the displayed token secret — it's shown only once

### If using privilege separation

Create a role and assign permissions:

```bash
# Create role
pveum role add TerraformRole -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit SDN.Use"

# Create user (optional, can use root@pam instead)
pveum user add terraform@pve

# Create token
pveum user token add terraform@pve monitoring

# Assign role to token on /
pveum acl modify / -token 'terraform@pve!monitoring' -role TerraformRole
```

### Token format for terraform.tfvars

```
proxmox_api_token = "terraform@pve!monitoring=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

## Snippets Storage

Cloud-init user-data requires a datastore with **snippets** content type enabled.

The `local` datastore supports snippets by default. If using a different datastore, enable it:

1. Proxmox UI -> **Datacenter** -> **Storage** -> select your datastore
2. Under **Content**, ensure **Snippets** is checked
