# MicroVM - KubeVirt Virtual Machines

Deploy lightweight virtual machines on Kubernetes using KubeVirt technology.

## What is This?

This Helm chart deploys KubeVirt VirtualMachine resources for running actual VMs on your Kubernetes cluster. Perfect for:

- **Legacy Applications** - Run software that requires a full OS
- **Windows Workloads** - Deploy Windows VMs alongside containers
- **Edge Computing** - Lightweight VMs at the edge
- **Kernel Isolation** - When containers aren't isolated enough
- **Testing & Development** - Quick VM provisioning

## Prerequisites

- KubeVirt operator installed (`kubevirt-system` namespace)
- Nodes with hardware virtualization enabled (KVM)
- CDI for persistent volumes (optional)

## Quick Deploy

```bash
helm install my-vm ./microvm
```

Default VM:
- 2 CPU cores, 2GB RAM
- openSUSE Tumbleweed
- User: suse / Password: suse
- Pod networking

## Resource Presets

- **micro**: 1 CPU, 512Mi RAM
- **small**: 1 CPU, 1Gi RAM  
- **medium**: 2 CPU, 2Gi RAM (default)
- **large**: 4 CPU, 4Gi RAM
- **xlarge**: 8 CPU, 8Gi RAM

## Access Your VM

```bash
# Check status
kubectl get vmi

# SSH access
virtctl ssh suse@microvm

# VNC console
virtctl vnc microvm

# Serial console
virtctl console microvm
```

## Popular Images

- `quay.io/containerdisks/opensuse-tumbleweed:1.0.0`
- `quay.io/containerdisks/ubuntu:22.04`
- `quay.io/containerdisks/fedora:latest`

## Common Configurations

### Large Database VM
```bash
helm install postgres-vm ./microvm \
  --set vm.resourcePreset=xlarge \
  --set disks.boot.type=dataVolume \
  --set disks.boot.size=50Gi
```

### Small Edge Service
```bash
helm install edge-vm ./microvm \
  --set vm.resourcePreset=small \
  --set networking.type=pod
```

## Documentation

See [README.md](README.md) for complete documentation.

## Support

For issues and questions:
- GitHub: [fireball-industries/helm-charts](https://github.com/fireball-industries/helm-charts)
- Email: patrick@fireballindustries.com
