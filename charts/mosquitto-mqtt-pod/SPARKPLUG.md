# ⚡ Sparkplug B Implementation Guide

Complete guide for implementing Sparkplug B protocol with Eclipse Mosquitto MQTT broker.

---

## 📚 What is Sparkplug B?

Sparkplug B is an open-source specification that provides MQTT clients the framework to integrate data from industrial devices, sensors, and applications into a unified namespace. It was developed by Cirrus Link Solutions and Eclipse Foundation.

**Key Benefits:**
- **Unified Namespace**: Consistent topic structure across all devices
- **Auto-Discovery**: Automatic device registration and discovery
- **State Management**: Birth/Death certificates for connection state
- **Data Efficiency**: Protobuf encoding (optional)
- **Interoperability**: Works with Ignition, Node-RED, and other SCADA platforms

---

## 🏗️ Sparkplug B Architecture

### Topic Structure

```
spBv1.0/<group_id>/<message_type>/<edge_node_id>[/<device_id>]
```

- **Namespace**: `spBv1.0` (Sparkplug B version 1.0)
- **Group ID**: Logical grouping (Factory, Warehouse, etc.)
- **Message Type**: NBIRTH, NDEATH, DBIRTH, DDEATH, NDATA, DDATA, NCMD, DCMD, STATE
- **Edge Node ID**: Unique edge node identifier
- **Device ID**: Device under edge node (optional)

### Message Types

| Type | Description | Direction | QoS |
|------|-------------|-----------|-----|
| **NBIRTH** | Edge Node Birth Certificate | Edge → SCADA | 1 |
| **NDEATH** | Edge Node Death Certificate (LWT) | Broker → SCADA | 1 |
| **DBIRTH** | Device Birth Certificate | Edge → SCADA | 1 |
| **DDEATH** | Device Death Certificate | Edge → SCADA | 1 |
| **NDATA** | Edge Node Data | Edge → SCADA | 0/1 |
| **DDATA** | Device Data | Edge → SCADA | 0/1 |
| **NCMD** | Node Command | SCADA → Edge | 1 |
| **DCMD** | Device Command | SCADA → Edge | 1 |
| **STATE** | Primary App State | SCADA → All | 1 |

---

## 🚀 Quick Start

### Enable Sparkplug B in Mosquitto

```yaml
mqtt:
  sparkplug:
    enabled: true
    namespace: "spBv1.0"
    aclEnabled: true
    groupIds:
      - "Factory"
      - "Warehouse"
```

Deploy:

```bash
helm install mosquitto . --namespace iot --values sparkplug-values.yaml
```

---

## 🔐 ACL Configuration for Sparkplug B

### Edge Node Permissions

```yaml
mqtt:
  acl:
    enabled: true
    content: |
      # Edge Node: edge_factory_01
      user edge_factory_01
      # Node birth/death/data
      topic write spBv1.0/Factory/NBIRTH/edge_factory_01
      topic write spBv1.0/Factory/NDEATH/edge_factory_01
      topic write spBv1.0/Factory/NDATA/edge_factory_01
      # Device birth/death/data
      topic write spBv1.0/Factory/DBIRTH/edge_factory_01/#
      topic write spBv1.0/Factory/DDEATH/edge_factory_01/#
      topic write spBv1.0/Factory/DDATA/edge_factory_01/#
      # Read commands
      topic read spBv1.0/Factory/NCMD/edge_factory_01
      topic read spBv1.0/Factory/DCMD/edge_factory_01/#
      # Read STATE
      topic read STATE/#
```

### Primary Application (SCADA) Permissions

```yaml
# Primary Application (Ignition, etc.)
user primary_app
# Read all Sparkplug messages
topic read spBv1.0/#
# Write commands
topic write spBv1.0/+/NCMD/#
topic write spBv1.0/+/DCMD/#
# Write STATE
topic write STATE/#
```

---

## 📡 Message Flow

### 1. Primary Application Startup

```
SCADA → STATE/primary_app
Payload: {"online": true, "timestamp": 1234567890}
QoS: 1, Retained: true
```

### 2. Edge Node Connection (NBIRTH)

```
Edge → spBv1.0/Factory/NBIRTH/edge_factory_01
Payload: {
  "timestamp": 1234567890,
  "metrics": [
    {"name": "Node Control/Rebirth", "type": "Boolean", "value": false},
    {"name": "Properties/Version", "type": "String", "value": "1.0.0"}
  ],
  "seq": 0
}
QoS: 1
```

### 3. Edge Node Disconnection (NDEATH - Last Will)

```
Edge → spBv1.0/Factory/NDEATH/edge_factory_01
Payload: {"timestamp": 1234567890}
QoS: 1, Retained: false
```

### 4. Device Birth (DBIRTH)

```
Edge → spBv1.0/Factory/DBIRTH/edge_factory_01/Sensor-01
Payload: {
  "timestamp": 1234567890,
  "metrics": [
    {"name": "Temperature", "type": "Float", "value": 25.5},
    {"name": "Humidity", "type": "Float", "value": 55.0}
  ],
  "seq": 1
}
QoS: 1
```

### 5. Device Data (DDATA)

```
Edge → spBv1.0/Factory/DDATA/edge_factory_01/Sensor-01
Payload: {
  "timestamp": 1234567890,
  "metrics": [
    {"name": "Temperature", "value": 26.2}
  ],
  "seq": 2
}
QoS: 0
```

### 6. Command to Device (DCMD)

```
SCADA → spBv1.0/Factory/DCMD/edge_factory_01/Pump-01
Payload: {
  "timestamp": 1234567890,
  "metrics": [
    {"name": "SetSpeed", "value": 75}
  ]
}
QoS: 1
```

---

## 🛠️ Implementation Examples

### Edge Node (Python)

```python
import paho.mqtt.client as mqtt
import json
import time

broker = "mosquitto.iot.svc.cluster.local"
port = 1883
group_id = "Factory"
edge_node_id = "edge_factory_01"
namespace = "spBv1.0"

client = mqtt.Client()
client.username_pw_set("edge_factory_01", "password")

# Set Last Will (NDEATH)
ndeath_topic = f"{namespace}/{group_id}/NDEATH/{edge_node_id}"
ndeath_payload = json.dumps({"timestamp": int(time.time() * 1000)})
client.will_set(ndeath_topic, ndeath_payload, qos=1, retain=False)

def on_connect(client, userdata, flags, rc):
    # Subscribe to commands
    ncmd_topic = f"{namespace}/{group_id}/NCMD/{edge_node_id}"
    client.subscribe(ncmd_topic, qos=1)
    
    # Publish NBIRTH
    nbirth_topic = f"{namespace}/{group_id}/NBIRTH/{edge_node_id}"
    nbirth = {
        "timestamp": int(time.time() * 1000),
        "metrics": [
            {"name": "Node Control/Rebirth", "type": "Boolean", "value": False},
            {"name": "Properties/Version", "type": "String", "value": "1.0.0"}
        ],
        "seq": 0
    }
    client.publish(nbirth_topic, json.dumps(nbirth), qos=1)

client.on_connect = on_connect
client.connect(broker, port)

# Publish device data
seq = 1
while True:
    ndata_topic = f"{namespace}/{group_id}/NDATA/{edge_node_id}"
    ndata = {
        "timestamp": int(time.time() * 1000),
        "metrics": [
            {"name": "Temperature", "value": 25.5}
        ],
        "seq": seq
    }
    client.publish(ndata_topic, json.dumps(ndata), qos=0)
    seq += 1
    time.sleep(5)
```

### Primary Application (Node.js)

```javascript
const mqtt = require('mqtt');

const namespace = 'spBv1.0';
const client = mqtt.connect('mqtt://mosquitto.iot.svc.cluster.local:1883', {
  username: 'primary_app',
  password: 'password'
});

client.on('connect', () => {
  // Publish STATE
  client.publish(
    'STATE/primary_app',
    JSON.stringify({ online: true, timestamp: Date.now() }),
    { qos: 1, retain: true }
  );
  
  // Subscribe to all Sparkplug messages
  client.subscribe(`${namespace}/#`, { qos: 1 });
});

client.on('message', (topic, message) => {
  const parts = topic.split('/');
  const messageType = parts[2];
  const edgeNode = parts[3];
  
  const payload = JSON.parse(message.toString());
  
  console.log(`Received ${messageType} from ${edgeNode}:`, payload);
  
  // Send command to device
  if (messageType === 'DBIRTH') {
    const device = parts[4];
    const cmdTopic = `${namespace}/${parts[1]}/DCMD/${edgeNode}/${device}`;
    const cmd = {
      timestamp: Date.now(),
      metrics: [{ name: 'SetPoint', value: 50 }]
    };
    client.publish(cmdTopic, JSON.stringify(cmd), { qos: 1 });
  }
});
```

---

## 🔄 Sequence Number Management

Sparkplug B uses sequence numbers (seq) to detect message loss:

1. **Reset on BIRTH**: Sequence starts at 0 after NBIRTH/DBIRTH
2. **Increment on DATA**: Each NDATA/DDATA increments seq
3. **Rebirth Trigger**: Primary app can request rebirth if seq gap detected

---

## 🎯 Best Practices

### 1. Use Retained STATE Messages

```yaml
mqtt:
  persistence:
    retainedMessages: true
```

### 2. Set Proper QoS Levels

- BIRTH/DEATH: QoS 1 (guaranteed delivery)
- DATA: QoS 0 (real-time, loss acceptable) or QoS 1 (critical data)
- CMD: QoS 1 (commands must be delivered)

### 3. Implement Rebirth Mechanism

Edge nodes should support rebirth requests from primary application.

### 4. Use Descriptive Metric Names

```json
{
  "metrics": [
    {"name": "Motor/Speed", "value": 1500},
    {"name": "Motor/Current", "value": 12.5},
    {"name": "Motor/Status", "value": "Running"}
  ]
}
```

### 5. Monitor STATE Messages

Primary application should publish STATE on connect/disconnect.

---

## 🔌 Integration with Ignition

### Ignition Edge MQTT Engine Setup

1. Install **MQTT Engine** module
2. Configure MQTT Transmission:
   - Server: `mosquitto.iot.svc.cluster.local:1883`
   - Client ID: `edge_factory_01`
   - Username/Password: Configure in Mosquitto
   - Primary Host ID: Leave blank for edge nodes

3. Set Sparkplug Settings:
   - Namespace: `spBv1.0`
   - Group ID: `Factory`
   - Edge Node ID: `edge_factory_01`

4. Configure Tags:
   - Add tags in Ignition Edge
   - Tags automatically publish as Sparkplug metrics

---

## 🧪 Testing Sparkplug B

### Using PowerShell Script

```powershell
.\scripts\test-mosquitto.ps1 -TestType sparkplug
```

### Manual Testing

```bash
# Subscribe to all Sparkplug messages
mosquitto_sub -h mosquitto.iot.svc.cluster.local -p 1883 \
  -t "spBv1.0/#" -v

# Publish NBIRTH
mosquitto_pub -h mosquitto.iot.svc.cluster.local -p 1883 \
  -t "spBv1.0/Factory/NBIRTH/test_edge" \
  -m '{"timestamp":1234567890,"metrics":[],"seq":0}' \
  -q 1

# Publish NDATA
mosquitto_pub -h mosquitto.iot.svc.cluster.local -p 1883 \
  -t "spBv1.0/Factory/NDATA/test_edge" \
  -m '{"timestamp":1234567890,"metrics":[{"name":"Temp","value":25.5}],"seq":1}' \
  -q 0
```

---

## 📚 Additional Resources

- [Sparkplug Specification](https://www.eclipse.org/tahu/spec/Sparkplug%20Topic%20Namespace%20and%20State%20ManagementV2.2-with%20appendix%20B%20format%20-%20Eclipse.pdf)
- [Cirrus Link Sparkplug](https://www.cirrus-link.com/mqtt-sparkplug-tahu/)
- [Ignition MQTT Engine](https://inductiveautomation.com/ignition/modules/mqtt-engine)

---

**Remember**: Sparkplug B is more than just a topic structure—it's a complete state management system for industrial IoT!
