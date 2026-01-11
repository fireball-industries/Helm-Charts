# ========================================
# CODESYS TargetVisu for Linux SL
# Multi-stage Docker Build
# ========================================
# "Because containerizing proprietary industrial
# software is basically an extreme sport."
# ========================================

# ========================================
# Stage 1: Builder
# ========================================
FROM debian:bookworm-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    libssl3 \
    libcurl4 \
    dpkg-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy CODESYS TargetVisu package (user provides this)
# Place the .deb file in the docker/ directory before building
# Download from: https://store.codesys.com/
COPY codesys-targetvisu-*.deb /tmp/

# Install CODESYS TargetVisu
# This might fail on dependencies - that's expected
RUN dpkg -i /tmp/codesys-targetvisu-*.deb || true

# Fix any dependency issues
RUN apt-get update && apt-get -f install -y \
    && rm -rf /var/lib/apt/lists/*

# Verify installation
RUN test -d /opt/codesys || (echo "CODESYS installation failed!" && exit 1)

# ========================================
# Stage 2: Runtime
# ========================================
FROM debian:bookworm-slim

LABEL maintainer="Patrick Ryan <patrick@fireballindustries.com>"
LABEL org.opencontainers.image.title="CODESYS TargetVisu for Linux SL"
LABEL org.opencontainers.image.description="Industrial HMI/SCADA visualization runtime for Kubernetes"
LABEL org.opencontainers.image.vendor="Fireball Industries"
LABEL org.opencontainers.image.url="https://github.com/fireball-industries/codesys-targetvisu-pod"
LABEL org.opencontainers.image.documentation="https://github.com/fireball-industries/codesys-targetvisu-pod/blob/main/README.md"
LABEL org.opencontainers.image.source="https://github.com/fireball-industries/codesys-targetvisu-pod"
LABEL humor.level="existential"
LABEL coffee.required="yes"

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libssl3 \
    libcurl4 \
    libxml2 \
    libxslt1.1 \
    fonts-liberation \
    fonts-dejavu-core \
    ca-certificates \
    curl \
    netcat-traditional \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copy CODESYS from builder
COPY --from=builder /opt/codesys /opt/codesys
COPY --from=builder /var/opt/codesys /var/opt/codesys
COPY --from=builder /usr/lib/*codesys* /usr/lib/ || true

# Create runtime user
# Note: Some CODESYS components may require root - adjust as needed
RUN useradd -r -u 1000 -s /bin/false -d /var/opt/codesys codesys \
    && mkdir -p /var/opt/codesys /projects /var/log/codesys \
    && chown -R codesys:codesys /var/opt/codesys /projects /var/log/codesys

# Create directories for persistent volumes
RUN mkdir -p \
    /var/opt/codesys/config \
    /var/opt/codesys/license \
    /projects \
    /var/log/codesys

# Set permissions
RUN chmod 755 /opt/codesys/bin/* || true

# Copy entrypoint and healthcheck scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/healthcheck.sh

# Volumes
VOLUME ["/var/opt/codesys", "/projects", "/var/log/codesys"]

# Expose ports
# Web interface
EXPOSE 8080/tcp
EXPOSE 8443/tcp
# WebVisu
EXPOSE 8081/tcp
# OPC UA
EXPOSE 4840/tcp
# Modbus TCP
EXPOSE 502/tcp
# EtherNet/IP
EXPOSE 44818/tcp
# CODESYS Gateway
EXPOSE 11740/tcp
# Prometheus metrics
EXPOSE 9100/tcp
# VNC (optional)
EXPOSE 5900/tcp

# Health check
# Checks if the web server is responding
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=60s \
  CMD /usr/local/bin/healthcheck.sh

# Switch to runtime user (comment out if CODESYS requires root)
# USER codesys

# Working directory
WORKDIR /opt/codesys

# Environment variables
ENV CODESYS_HOME=/opt/codesys \
    CODESYS_CONFIG=/var/opt/codesys \
    CODESYS_PROJECTS=/projects \
    CODESYS_LOGS=/var/log/codesys \
    PATH=/opt/codesys/bin:$PATH

# Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command (override in Kubernetes)
CMD ["/opt/codesys/bin/codesysvisu"]

# ========================================
# Build Instructions:
# ========================================
# 1. Download CODESYS TargetVisu for Linux SL .deb package
# 2. Place it in the docker/ directory
# 3. Build: docker build -t codesys-targetvisu:3.5.20.0 .
# 4. Tag for registry: docker tag codesys-targetvisu:3.5.20.0 ghcr.io/fireball-industries/codesys-targetvisu:3.5.20.0
# 5. Push: docker push ghcr.io/fireball-industries/codesys-targetvisu:3.5.20.0
#
# Multi-arch build (amd64, arm64, armv7):
# docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 \
#   -t ghcr.io/fireball-industries/codesys-targetvisu:3.5.20.0 \
#   --push .
# ========================================
