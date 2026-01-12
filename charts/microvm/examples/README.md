# Examples

This directory contains example configurations for deploying MicroVMs with different use cases.

## Basic Examples

### Minimal Testing VM

```yaml
# minimal-vm.yaml
vm:
  resourcePreset: micro
  runStrategy: Manual
  
disks:
  boot:
    type: containerDisk
    image: quay.io/containerdisks/alpine:latest

cloudInit:
  enabled: true
  userData: |
    #cloud-config
    users:
      - name: test
        plain_text_passwd: 'test'
```

Deploy:
```bash
helm install test-vm ./microvm -f examples/minimal-vm.yaml
virtctl start test-vm
```

### Ubuntu Desktop

```yaml
# ubuntu-desktop.yaml
vm:
  resourcePreset: large
  hostname: ubuntu-desktop

disks:
  boot:
    type: dataVolume
    size: 30Gi
    image: quay.io/containerdisks/ubuntu:22.04

console:
  vnc:
    enabled: true

cloudInit:
  enabled: true
  userData: |
    #cloud-config
    users:
      - name: ubuntu
        groups: sudo
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - ssh-rsa AAAAB3...your-key...
    packages:
      - ubuntu-desktop
      - firefox
```

### Web Server with Ingress

```yaml
# web-server.yaml
vm:
  resourcePreset: medium
  hostname: webserver

disks:
  boot:
    type: dataVolume
    size: 20Gi

cloudInit:
  enabled: true
  userData: |
    #cloud-config
    packages:
      - nginx
    runcmd:
      - systemctl enable nginx
      - systemctl start nginx
      - echo "Hello from VM" > /var/www/html/index.html

service:
  enabled: true
  type: ClusterIP
  ports:
    - name: http
      port: 80
      targetPort: 80

ingress:
  enabled: true
  host: webserver.example.com
  className: nginx
  servicePort: 80
```

### PostgreSQL Database

```yaml
# postgres-vm.yaml
vm:
  resourcePreset: xlarge
  hostname: postgres-vm

disks:
  boot:
    type: dataVolume
    size: 20Gi
  additional:
    - name: pgdata
      type: dataVolume
      size: 100Gi
      storageClass: fast-ssd

cloudInit:
  enabled: true
  userData: |
    #cloud-config
    packages:
      - postgresql
      - postgresql-contrib
    runcmd:
      - systemctl enable postgresql
      - systemctl start postgresql

service:
  enabled: true
  type: ClusterIP
  ports:
    - name: postgres
      port: 5432
      targetPort: 5432

monitoring:
  enabled: true
```

### Windows Server

```yaml
# windows-vm.yaml
vm:
  resourcePreset: large
  hostname: windows-server
  machineType: q35

features:
  efi:
    enabled: true
    secureBoot: false

disks:
  boot:
    type: dataVolume
    size: 60Gi
    image: registry.example.com/windows-server-2022

console:
  vnc:
    enabled: true
  serial:
    enabled: false
```

### Edge Gateway with Persistent Storage

```yaml
# edge-gateway.yaml
vm:
  resourcePreset: small
  runStrategy: Always
  hostname: edge-gateway

disks:
  boot:
    type: dataVolume
    size: 10Gi
    storageClass: local-path
  additional:
    - name: data
      type: dataVolume
      size: 20Gi
      storageClass: local-path

networking:
  type: pod
  pod:
    masquerade: true

nodeSelector:
  node-role.kubernetes.io/edge: "true"

advanced:
  evictionStrategy: None

cloudInit:
  enabled: true
  userData: |
    #cloud-config
    packages:
      - iptables
      - dnsmasq
      - mosquitto
    runcmd:
      - systemctl enable mosquitto
      - systemctl start mosquitto
```

### High-Performance Compute

```yaml
# hpc-vm.yaml
vm:
  resourcePreset: custom
  resources:
    cpu: 16
    memory: 32Gi

advanced:
  dedicatedCpuPlacement: true
  cpuModel: host-passthrough

disks:
  boot:
    type: dataVolume
    size: 50Gi
    storageClass: fast-ssd

nodeSelector:
  node-type: compute

features:
  acpi: true
```

### Multi-Disk Development VM

```yaml
# dev-vm.yaml
vm:
  resourcePreset: large
  hostname: dev-workstation

disks:
  boot:
    type: dataVolume
    size: 30Gi
  additional:
    - name: home
      type: dataVolume
      size: 50Gi
      storageClass: standard
    - name: projects
      type: dataVolume
      size: 100Gi
      storageClass: standard
    - name: cache
      type: ephemeral
      size: 20Gi

cloudInit:
  enabled: true
  userData: |
    #cloud-config
    users:
      - name: developer
        groups: sudo,docker
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          - ssh-rsa AAAAB3...
    packages:
      - git
      - docker
      - vim
      - build-essential
```

## Deploy Examples

```bash
# Deploy any example
helm install my-vm ./microvm -f examples/<example-file>.yaml

# Check status
kubectl get vm
kubectl get vmi

# Access VM
virtctl ssh user@my-vm
virtctl vnc my-vm
```

## Customize

Copy an example and modify for your needs:

```bash
cp examples/web-server.yaml my-custom-vm.yaml
# Edit my-custom-vm.yaml
helm install custom-vm ./microvm -f my-custom-vm.yaml
```
