# CODESYS TargetVisu Docker Build

This directory contains the Docker build files for CODESYS TargetVisu for Linux SL.

## Prerequisites

1. **CODESYS TargetVisu Package**: Download the `.deb` package from [CODESYS Store](https://store.codesys.com/)
2. **Docker** or **Podman** installed
3. **Valid CODESYS License** (or use demo mode)

## Build Instructions

### Standard Build (Single Architecture)

```bash
# 1. Place CODESYS .deb package in this directory
cp /path/to/codesys-targetvisu-*.deb ./

# 2. Build the image
docker build -t codesys-targetvisu:3.5.20.0 .

# 3. Tag for your registry
docker tag codesys-targetvisu:3.5.20.0 ghcr.io/YOUR-ORG/codesys-targetvisu:3.5.20.0

# 4. Push to registry
docker push ghcr.io/YOUR-ORG/codesys-targetvisu:3.5.20.0
```

### Multi-Architecture Build

For edge deployments (Raspberry Pi, ARM servers):

```bash
# Enable buildx
docker buildx create --name multiarch --use

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t ghcr.io/YOUR-ORG/codesys-targetvisu:3.5.20.0 \
  --push \
  .
```

**Note**: Multi-arch requires platform-specific CODESYS packages. You may need to build separately for each architecture.

## Testing the Image

### Run Locally

```bash
docker run -d \
  --name codesys-targetvisu \
  -p 8080:8080 \
  -p 8443:8443 \
  -p 8081:8081 \
  -v $(pwd)/config:/var/opt/codesys \
  -v $(pwd)/projects:/projects \
  -v $(pwd)/logs:/var/log/codesys \
  codesys-targetvisu:3.5.20.0
```

### Check Health

```bash
# View logs
docker logs -f codesys-targetvisu

# Check health
docker exec codesys-targetvisu /usr/local/bin/healthcheck.sh

# Access HMI
open http://localhost:8080
```

## License Handling

### Option 1: License File

```bash
# Create license secret
mkdir -p license
cp /path/to/your.lic license/

# Mount as volume
docker run -d \
  -v $(pwd)/license:/var/opt/codesys/license:ro \
  codesys-targetvisu:3.5.20.0
```

### Option 2: License Server

Set environment variables:

```bash
docker run -d \
  -e LICENSE_TYPE=server \
  -e LICENSE_SERVER=license.example.com:1947 \
  codesys-targetvisu:3.5.20.0
```

### Option 3: Demo Mode

No configuration needed - runs in trial mode (30 days).

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CODESYS_WEB_PORT` | 8080 | HTTP port |
| `CODESYS_HTTPS_PORT` | 8443 | HTTPS port |
| `CODESYS_WEBVISU_PORT` | 8081 | WebVisu port |
| `CODESYS_MAX_CLIENTS` | 10 | Max concurrent clients |
| `CODESYS_LOG_LEVEL` | info | Log level (debug, info, warn, error) |
| `OPCUA_ENABLED` | false | Enable OPC UA |
| `OPCUA_PORT` | 4840 | OPC UA port |
| `MODBUS_TCP_ENABLED` | false | Enable Modbus TCP |
| `MODBUS_TCP_PORT` | 502 | Modbus TCP port |
| `PROMETHEUS_ENABLED` | false | Enable metrics |
| `PROMETHEUS_PORT` | 9100 | Metrics port |

## Troubleshooting

### Image Build Fails

**Problem**: `dpkg: dependency problems`

**Solution**: The Dockerfile handles this with `apt-get -f install`. If it still fails, check that you have the correct `.deb` package for your base image (Debian Bookworm).

### Container Won't Start

**Problem**: `CODESYS executable not found`

**Solution**: Verify the CODESYS package installed correctly:
```bash
docker run -it --rm codesys-targetvisu:3.5.20.0 /bin/bash
ls -la /opt/codesys/bin/
```

### No License File

**Problem**: Running in demo mode unintentionally

**Solution**: Check the license mount:
```bash
docker exec codesys-targetvisu ls -la /var/opt/codesys/license/
```

### Port Already in Use

**Problem**: `Error: port is already allocated`

**Solution**: Use different host ports:
```bash
docker run -d -p 9080:8080 -p 9443:8443 codesys-targetvisu:3.5.20.0
```

## Security Considerations

### Running as Non-Root

By default, the container runs as root because CODESYS requires certain privileges. For production:

1. Review CODESYS requirements
2. Use security contexts in Kubernetes
3. Apply SELinux/AppArmor policies
4. Enable read-only root filesystem where possible

### Network Policies

In production Kubernetes:
- Enable NetworkPolicy
- Restrict ingress to necessary ports
- Limit egress to PLC networks only

## Performance Tuning

### Resource Limits

Recommended Docker resource limits:

```bash
docker run -d \
  --cpus="2.0" \
  --memory="2g" \
  --memory-swap="2g" \
  codesys-targetvisu:3.5.20.0
```

### Volume Performance

For better I/O performance, use volume drivers optimized for your storage:

```bash
docker volume create --driver local \
  --opt type=none \
  --opt device=/fast/storage/path \
  --opt o=bind \
  codesys-projects
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Build and Push Image

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Download CODESYS Package
        run: |
          # Download from your artifact storage
          wget -O docker/codesys-targetvisu.deb ${{ secrets.CODESYS_PACKAGE_URL }}
      
      - name: Build and Push
        uses: docker/build-push-action@v4
        with:
          context: ./docker
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.ref_name }}
```

## Support

For issues with:
- **CODESYS Software**: [CODESYS Support](https://www.codesys.com/support.html)
- **This Container**: [GitHub Issues](https://github.com/fireball-industries/codesys-targetvisu-pod/issues)
- **Existential Dread**: Coffee

---

**Made with 💀 by Fireball Industries**

*"Because containerizing proprietary industrial software is basically an extreme sport."*
