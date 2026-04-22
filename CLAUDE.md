# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

LibreNMS network monitoring for Randers Motor Sport (motocross club in Denmark). Deploys as Infrastructure-as-Code on Proxmox. Monitors ~50 network devices (UniFi APs, D-Link switches, NVRs, PCs) via SNMP auto-discovery and ping across two subnets: `10.0.0.0/24` and `10.7.5.0/24`.

## Architecture

Three-phase deployment, each building on the previous:

1. **Terraform** (runs on Windows PC) → provisions a Debian 13 VM on Proxmox (`10.0.0.99`) via the bpg/proxmox provider. Cloud-init bootstraps the VM with packages, SSH keys, and clones this repo to `/opt/monitoring`.

2. **Ansible** (runs locally on the VM, `connection: local`) → installs Docker CE, templates `docker-compose.yml` + `.env` from Jinja2, starts the LibreNMS stack, configures UFW firewall.

3. **Bootstrap script** (`scripts/bootstrap.sh`) → seeds LibreNMS config via `docker exec librenms lnms` CLI: discovery networks, SNMP community, device groups. Uses `.bootstrapped` marker file for idempotency.

The standalone `docker-compose.yml` at repo root is a reference copy. The actual deployed file is templated from `ansible/roles/librenms/templates/docker-compose.yml.j2`.

## Commands

```bash
# Terraform (from Windows PC, in terraform/ directory)
terraform init
terraform plan
terraform apply
terraform destroy

# Ansible (SSH into VM, from /opt/monitoring)
sudo ansible-playbook ansible/playbook.yml

# Bootstrap (SSH into VM)
sudo bash scripts/bootstrap.sh

# Docker Compose (SSH into VM, from /opt/monitoring)
sudo docker compose up -d
sudo docker compose ps
sudo docker logs librenms --tail 50
sudo docker logs librenms-db --tail 50

# LibreNMS CLI (via container)
sudo docker exec librenms lnms config:set <key> <value>
sudo docker exec librenms lnms device:add <hostname>

# SNMP testing (on VM)
snmpwalk -v2c -c public <device-ip> sysDescr
```

## Key conventions

- **User preference:** Always use `PowerShell` tool, never `Bash` tool.
- **Timezone:** `Europe/Copenhagen` — hardcoded in cloud-init, Ansible vars, and compose templates.
- **Terraform state:** Local file, `.gitignore`d. Recovery: `terraform import proxmox_virtual_environment_vm.monitoring proxmox/qemu/<vmid>`.
- **Secrets:** `terraform.tfvars` and `.env` are `.gitignore`d. Example files (`*.example`) are committed. Never commit API tokens or passwords.
- **MariaDB:** Uses `mariadbd` (not `mysqld`) — binary was renamed in MariaDB 11.
- **Cloud-init runcmd:** Use YAML list syntax (`["cmd", "arg"]`) not string syntax to avoid colon-parsing issues.
- **Proxmox node:** `rms-prox01` (not the default `pve`).
- **VM IP:** `10.0.0.2/24` — must include CIDR suffix in Terraform.
- **Branching:** Feature work on `feature/*` branches, merge to `main`. The VM's repo clone tracks `main`.
