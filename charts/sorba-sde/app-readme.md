# Sorba AI SDE

## Industrial IoT Data Collection & Edge Analytics Platform

The Sorba AI Smart Data Engine (SDE) is a comprehensive industrial data collection and gateway device designed for modern manufacturing and industrial operations.

### Key Features

- **Multi-Protocol Support**: Connect to devices using Modbus TCP, MQTT, OPC UA, and more
- **Edge Analytics**: Process and analyze data at the edge with built-in machine learning capabilities
- **Real-Time Data Collection**: Simultaneous communication with multiple industrial devices
- **Hardware Agnostic**: Works with any sensor or industrial equipment
- **Remote Management**: Easy access for troubleshooting and remote programming of PLCs & HMIs
- **Point & Click Configuration**: Intuitive interface for quick setup

### Deployment Modes

**Demo Mode (Default)**
- No license required
- Full feature evaluation
- Perfect for testing and development
- Default deployment configuration

**Licensed Mode**
- Production features unlocked
- Requires static MAC address configuration
- Contact Sorbotics for licensing: support@sorbotics.com

### Ports & Protocols

| Port  | Protocol | Service            |
|-------|----------|--------------------|
| 443   | HTTPS    | Web UI             |
| 502   | TCP      | Modbus TCP Server  |
| 1883  | TCP      | MQTT Broker        |
| 49321 | TCP      | OPC UA Server      |

### System Requirements

- **CPU**: Minimum 6 cores (8 cores recommended)
- **Memory**: Minimum 16GB RAM (20GB recommended)
- **Storage**: Minimum 20GB persistent volume

### Default Credentials

After installation, access the web UI using:
- **Username**: admin
- **Password**: adminpwd

⚠️ **IMPORTANT**: Change the password immediately after first login!

### Quick Start

1. Deploy the application using Rancher's UI
2. Configure storage and resource requirements
3. Access via the configured service type (port-forward, NodePort, LoadBalancer, or Ingress)
4. Login and change default password
5. Begin configuring your industrial data sources

### Support

- **Email**: support@sorbotics.com
- **Documentation**: https://www.sorbotics.com/docs
- **GitHub**: https://github.com/sorbotics/sorbotics-pod

### License

This Helm chart is MIT licensed. The SORBA SDE software is subject to its own license terms.

---

*For detailed configuration and deployment options, see the full documentation in the chart repository.*
