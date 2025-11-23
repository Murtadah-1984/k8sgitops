# Ansible Playbooks for Ceph Node Preparation

This directory contains Ansible playbooks for preparing Ceph nodes before deploying Rook-Ceph via ArgoCD.

## Inventory

Edit `inventory/hosts.ini` with your actual node IPs and SSH credentials.

## Playbooks

### 1. `ceph-node-prepare.yml`
Prepares all Ceph nodes (mon + OSD) with:
- Required packages (lvm2, nvme-cli, etc.)
- Swap disabled
- Ceph-optimized sysctl settings
- Time synchronization (chrony)

**Usage:**
```bash
ansible-playbook -i inventory/hosts.ini playbooks/ceph-node-prepare.yml
```

### 2. `ceph-osd-disks.yml`
Wipes and prepares OSD disks on OSD nodes. **WARNING**: This will destroy all data on specified disks.

**Usage:**
```bash
ansible-playbook -i inventory/hosts.ini playbooks/ceph-osd-disks.yml
```

**Note**: Only run this on fresh disks or when you want to completely wipe OSD data.

### 3. `ceph-label-nodes.yml`
Labels Kubernetes nodes for Ceph placement. Requires working kubeconfig.

**Usage:**
```bash
ansible-playbook -i inventory/hosts.ini playbooks/ceph-label-nodes.yml
```

## Disaster Recovery

During disaster recovery:
1. **DO** run `ceph-node-prepare.yml` to ensure OS-level settings
2. **DO NOT** run `ceph-osd-disks.yml` if you want to preserve existing Ceph data
3. **DO** run `ceph-label-nodes.yml` to restore node labels

## Node Labels

The playbooks use these labels:
- `ceph-mon=enabled` - Nodes allowed to run Ceph monitors
- `ceph-osd=enabled` - Nodes allowed to run Ceph OSDs

These match the node affinity in the Rook-Ceph Helm chart.

