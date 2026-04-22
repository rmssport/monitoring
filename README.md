# RMS Monitoring

Network monitoring for Randers Motor Sport using [LibreNMS](https://www.librenms.org/).

Monitors ~50 network devices (UniFi APs, switches, D-Link switches, NVRs, PCs) via SNMP auto-discovery and ping. Deployed as Infrastructure-as-Code on Proxmox.

## Architecture

```
Windows PC (Terraform) ──► Proxmox (10.0.0.99) ──► Debian 13 VM
                                                         │
                                                    Ansible (local)
                                                         │
                                                    Docker Compose
                                                         │
                          ┌──────────────────────────────┼──────────────────────────┐
                          │              LibreNMS Stack   │                          │
                          │  ┌──────────┐ ┌───────────┐ ┌──────────┐ ┌───────────┐ │
                          │  │ LibreNMS │ │Dispatcher │ │ Syslog   │ │ SNMPtrapd │ │
                          │  │ :8000    │ │           │ │ :514     │ │ :162/udp  │ │
                          │  └────┬─────┘ └─────┬─────┘ └────┬─────┘ └─────┬─────┘ │
                          │       └──────┬──────┘            └──────┬──────┘        │
                          │         ┌────┴────┐  ┌────────┐  ┌─────┴──┐            │
                          │         │MariaDB  │  │ Redis  │  │RRDcache│            │
                          │         └─────────┘  └────────┘  └────────┘            │
                          └────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **Proxmox:** Create a Debian 13 cloud-init template ([instructions](docs/proxmox-template-setup.md))
2. **Proxmox:** Create an API token for Terraform ([instructions](docs/proxmox-template-setup.md#api-token))
3. **Windows PC:** Install [Terraform CLI](https://developer.hashicorp.com/terraform/install)
4. **Windows PC:** Generate an SSH key pair (`ssh-keygen -t ed25519`)

## Deployment

### 1. Provision the VM with Terraform

```powershell
cd terraform
Copy-Item terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values (Proxmox IP, API token, VM IP, SSH key, etc.)

terraform init
terraform plan
terraform apply
```

Terraform outputs the SSH command and LibreNMS URL when done.

### 2. Configure the VM with Ansible

```bash
ssh rms@<vm-ip>
cd /opt/monitoring
ansible-playbook ansible/playbook.yml
```

This installs Docker, deploys the LibreNMS stack, configures the firewall, and runs the bootstrap script.

### 3. Access LibreNMS

Open `http://<vm-ip>:8000` in your browser. On first visit, create the admin user.

Devices on `10.7.5.0/24` and `10.0.0.0/24` are scanned via SNMP on first boot and re-scanned daily at 02:00 by a cron job (`/etc/cron.d/snmp-scan`). Check scan results in `/var/log/snmp-scan.log`. Add ping-only devices (PCs, NVRs without SNMP) manually via the web UI.

## What gets monitored automatically

- **Ubiquiti UniFi APs:** wireless clients, signal, channel utilization, per-port traffic
- **UniFi switches:** per-port bandwidth, PoE status, errors, discards
- **D-Link DGS-1210:** per-port interface stats
- **All devices:** ping up/down, latency, packet loss

## Dashboard

- **Availability Map** — color-coded tiles (green/yellow/red) grouped by device group
- **Custom Maps** — place devices on a facility layout with link utilization
- **Wall display** — create a read-only user, browser in kiosk mode

## Recovery

If the VM is lost (hosting is not HA):

```powershell
cd terraform
terraform apply          # Recreates the VM

ssh rms@<vm-ip>
cd /opt/monitoring
ansible-playbook ansible/playbook.yml    # Reinstalls everything
```

LibreNMS auto-discovers all devices again. Historical metrics are lost unless restored from backup.

Optional: configure `lnms backup` cron job for regular backups.

## Project Structure

```
terraform/           Proxmox VM provisioning (IaC)
ansible/             VM configuration (Docker, LibreNMS, firewall)
docker-compose.yml   LibreNMS stack (standalone reference)
scripts/             Post-deploy bootstrap (lnms CLI)
docs/                Setup guides
```
