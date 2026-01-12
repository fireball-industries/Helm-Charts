# MicroVM - KubeVirt Virtual Machine Helm Chart

Deploy lightweight virtual machines on Kubernetes using KubeVirt technology. Perfect for edge computing, legacy applications, and scenarios requiring kernel-level isolation.

## Features

- 🚀 **Quick Deployment** - Deploy VMs with a single Helm command
- 🎯 **Resource Presets** - Pre-configured CPU/memory profiles (micro to xlarge)
- 💾 **Flexible Storage** - Container disks, persistent volumes, or ephemeral storage
- ☁️ **Cloud-Init** - Automated VM configuration at boot
- 🌐 **Networking** - Pod network, Multus, or bridge networking
- 🔒 **Security** - UEFI Secure Boot, resource isolation
- 📊 **Monitoring** - Prometheus metrics integration
- 🖥️ **Console Access** - VNC and serial console support

## Prerequisites

1. **KubeVirt Operator** - Must be installed in your cluster
   ```bash
   helm install kubevirt oci://registry.suse.com/edge/charts/kubevirt \
     --namespace kubevirt-system --create-namespace
   ```

2. **Virtualization Support** - Nodes must have:
   - KVM/hardware virtualization enabled in BIOS
   - Kernel modules loaded (kvm, kvm_intel/kvm_amd)

3. **CDI (Optional)** - For persistent volume support
   ```bash
   helm install cdi oci://registry.suse.com/edge/charts/cdi \
     --namespace cdi-system --create-namespace
   ```

4. **virtctl CLI (Recommended)** - For VM management
   ```bash
   export VERSION=v1.5.2
   wget https://github.com/kubevirt/kubevirt/releases/download/$VERSION/virtctl-$VERSION-linux-amd64
   chmod +x virtctl-*
   mv virtctl-* /usr/local/bin/virtctl
   ```

## Quick Start

### Deploy a Basic VM

```bash
helm install my-vm ./microvm
```

This creates a VM with:
- 2 CPU cores, 2GB RAM (medium preset)
- openSUSE Tumbleweed container disk
- Default user: `suse` / password: `suse`
- Pod networking

### Access the VM

```bash
# Wait for VM to start
kubectl get vmi

# SSH via virtctl (requires network connectivity)
virtctl ssh suse@microvm

# VNC console
virtctl vnc microvm

# Serial console
virtctl console microvm
```

## Resource Presets

Quick deployment profiles:

| Preset  | CPU | Memory | Use Case |
|---------|-----|--------|----------|
| micro   | 1   | 512Mi  | Minimal services, testing |
| small   | 1   | 1Gi    | Light workloads, edge services |
| medium  | 2   | 2Gi    | Standard applications (default) |
| large   | 4   | 4Gi    | Heavy workloads, databases |
| xlarge  | 8   | 8Gi    | High-performance applications |
| custom  | -   | -      | Define your own resources |

Example:
```bash
helm install my-vm ./microvm --set vm.resourcePreset=large
```

## Storage Options

### Container Disk (Ephemeral)

Fastest boot time, data lost on restart:

```bash
helm install my-vm ./microvm \
  --set disks.boot.type=containerDisk \
  --set disks.boot.image=quay.io/containerdisks/ubuntu:22.04
```

Popular container disk images:
- `quay.io/containerdisks/opensuse-tumbleweed:1.0.0`
- `quay.io/containerdisks/ubuntu:22.04`
- `quay.io/containerdisks/fedora:latest`
- `quay.io/containerdisks/alpine:latest`

### Persistent Volume (Persistent)

Data survives restarts:

```bash
helm install my-vm ./microvm \
  --set disks.boot.type=dataVolume \
  --set disks.boot.size=20Gi \
  --set disks.boot.storageClass=local-path
```

## Cloud-Init Configuration

Customize VM initialization with cloud-init:

```yaml
cloudInit:
  enabled: true
  userData: |
    #cloud-config
    hostname: my-server
    users:
      - name: admin
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          - ssh-rsa AAAAB3...your-key...
    packages:
      - nginx
      - postgresql
    runcmd:
      - systemctl enable nginx
      - systemctl start nginx
```

## Networking

### Pod Networking (Default)

VM gets an IP on the pod network:

```bash
helm install my-vm ./microvm \
  --set networking.type=pod \
  --set networking.pod.masquerade=true
```

### Expose Services

Create a Kubernetes Service:

```yaml
service:
  enabled: true
  type: LoadBalancer
  ports:
    - name: ssh
      port: 22
      targetPort: 22
    - name: http
      port: 80
      targetPort: 80
```

### Ingress

Expose HTTP/HTTPS services:

```yaml
ingress:
  enabled: true
  host: myvm.example.com
  className: nginx
  servicePort: 80
  tls:
    enabled: true
    secretName: myvm-tls
```

## Examples

### Windows VM

```yaml
vm:
  resourcePreset: large
  machineType: q35
features:
  efi:
    enabled: true
    secureBoot: true
disks:
  boot:
    type: dataVolume
    size: 50Gi
    image: registry.example.com/windows-server-2022
```

### Database Server

```yaml
vm:
  resourcePreset: xlarge
  hostname: postgres-vm
disks:
  boot:
    type: dataVolume
    size: 20Gi
  additional:
    - name: data
      type: dataVolume
      size: 100Gi
      storageClass: fast-ssd
service:
  enabled: true
  type: ClusterIP
  ports:
    - name: postgres
      port: 5432
      targetPort: 5432
```

### Edge Gateway

```yaml
vm:
  resourcePreset: small
  runStrategy: Always
networking:
  type: pod
  pod:
    masquerade: true
nodeSelector:
  node-role.kubernetes.io/edge: "true"
advanced:
  evictionStrategy: None
```

## VM Lifecycle Management

```bash
# Start VM
kubectl patch vm microvm --type merge -p '{"spec":{"runStrategy":"Always"}}'

# Stop VM
kubectl patch vm microvm --type merge -p '{"spec":{"runStrategy":"Halted"}}'

# Restart VM
virtctl restart microvm

# Delete VM
kubectl delete vm microvm
```

## Monitoring

Enable Prometheus metrics:

```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
```

Metrics include:
- CPU usage
- Memory consumption
- Disk I/O
- Network traffic
- VM state

## Troubleshooting

### VM not starting

```bash
# Check VM status
kubectl get vm
kubectl get vmi

# View events
kubectl describe vm microvm

# Check virt-launcher pod
kubectl get pods | grep virt-launcher
kubectl logs <virt-launcher-pod>
```

### No network connectivity

```bash
# Verify pod network
kubectl get vmi microvm -o yaml | grep -A5 interfaces

# Check service
kubectl get svc microvm
```

### Can't access console

```bash
# Verify virtctl version matches KubeVirt
virtctl version

# Try serial console instead of VNC
virtctl console microvm
```

## Configuration Reference

See [values.yaml](values.yaml) for complete configuration options.

## License

Apache 2.0

## Maintainer

Patrick Ryan - [patrick@fireballindustries.com](mailto:patrick@fireballindustries.com)

## Resources

- [KubeVirt Documentation](https://kubevirt.io)
- [SUSE Edge Virtualization](https://documentation.suse.com/suse-edge/)
- [Cloud-Init Examples](https://cloudinit.readthedocs.io/)
