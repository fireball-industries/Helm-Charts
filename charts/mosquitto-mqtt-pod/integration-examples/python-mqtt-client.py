#!/usr/bin/env python3
"""
Mosquitto MQTT Broker - Python Client Example
Using paho-mqtt library

Install: pip install paho-mqtt

Author: Patrick Ryan - Fireball Industries
"""

import paho.mqtt.client as mqtt
import json
import time
from datetime import datetime

# ============================================================================
# Configuration
# ============================================================================

MQTT_BROKER = "mosquitto.iot.svc.cluster.local"
MQTT_PORT = 1883
MQTT_USERNAME = "sensor01"  # Set to None if no auth
MQTT_PASSWORD = "secret123"   # Set to None if no auth
MQTT_CLIENT_ID = "python-example-01"

# Topics
PUBLISH_TOPIC = "sensors/python-example/data"
SUBSCRIBE_TOPIC = "sensors/#"

# ============================================================================
# Callback Functions
# ============================================================================

def on_connect(client, userdata, flags, rc):
    """Callback when connected to broker"""
    if rc == 0:
        print(f"✅ Connected to MQTT broker: {MQTT_BROKER}:{MQTT_PORT}")
        print(f"   Client ID: {MQTT_CLIENT_ID}")
        
        # Subscribe to topics after connecting
        client.subscribe(SUBSCRIBE_TOPIC)
        print(f"📡 Subscribed to: {SUBSCRIBE_TOPIC}")
    else:
        print(f"❌ Connection failed with code {rc}")
        print("   Return codes:")
        print("   0: Success")
        print("   1: Incorrect protocol version")
        print("   2: Invalid client ID")
        print("   3: Server unavailable")
        print("   4: Bad username or password")
        print("   5: Not authorized")

def on_disconnect(client, userdata, rc):
    """Callback when disconnected from broker"""
    if rc != 0:
        print(f"⚠️  Unexpected disconnection (code {rc})")
    else:
        print("👋 Disconnected from broker")

def on_message(client, userdata, msg):
    """Callback when message received"""
    print(f"📥 Message received:")
    print(f"   Topic: {msg.topic}")
    print(f"   QoS: {msg.qos}")
    print(f"   Retained: {msg.retain}")
    
    # Try to parse JSON payload
    try:
        payload = json.loads(msg.payload.decode())
        print(f"   Payload: {json.dumps(payload, indent=2)}")
    except:
        print(f"   Payload: {msg.payload.decode()}")

def on_publish(client, userdata, mid):
    """Callback when message published"""
    print(f"✅ Message published (mid: {mid})")

def on_subscribe(client, userdata, mid, granted_qos):
    """Callback when subscribed to topic"""
    print(f"✅ Subscribed successfully (QoS: {granted_qos})")

def on_log(client, userdata, level, buf):
    """Callback for MQTT client logs"""
    print(f"🔍 Log: {buf}")

# ============================================================================
# Main Function
# ============================================================================

def main():
    """Main function"""
    print("🦟 Mosquitto MQTT - Python Client Example")
    print("   Fireball Industries - Patrick Ryan")
    print()
    
    # Create MQTT client
    client = mqtt.Client(client_id=MQTT_CLIENT_ID, clean_session=True)
    
    # Set callbacks
    client.on_connect = on_connect
    client.on_disconnect = on_disconnect
    client.on_message = on_message
    client.on_publish = on_publish
    client.on_subscribe = on_subscribe
    # client.on_log = on_log  # Uncomment for verbose logging
    
    # Set authentication if configured
    if MQTT_USERNAME and MQTT_PASSWORD:
        client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
        print(f"🔐 Using authentication: {MQTT_USERNAME}")
    
    # For TLS/SSL, add this:
    # client.tls_set(ca_certs="path/to/ca.crt",
    #                certfile="path/to/client.crt",
    #                keyfile="path/to/client.key")
    
    try:
        # Connect to broker
        print(f"🔌 Connecting to {MQTT_BROKER}:{MQTT_PORT}...")
        client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
        
        # Start network loop in background
        client.loop_start()
        
        # Publish messages in a loop
        print()
        print("📤 Publishing messages (Ctrl+C to stop)...")
        print()
        
        counter = 0
        while True:
            counter += 1
            
            # Create sensor data payload
            payload = {
                "sensor_id": "python-example-01",
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "temperature": 20.0 + (counter % 10),
                "humidity": 50.0 + (counter % 20),
                "counter": counter
            }
            
            # Publish with QoS 1
            result = client.publish(
                topic=PUBLISH_TOPIC,
                payload=json.dumps(payload),
                qos=1,
                retain=False
            )
            
            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                print(f"📤 Published message #{counter}")
            else:
                print(f"❌ Publish failed: {result.rc}")
            
            # Wait 5 seconds
            time.sleep(5)
            
    except KeyboardInterrupt:
        print()
        print("⏹️  Stopping...")
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        # Cleanup
        client.loop_stop()
        client.disconnect()
        print("👋 Goodbye!")

# ============================================================================
# Additional Examples
# ============================================================================

def example_qos_levels():
    """Example of different QoS levels"""
    client = mqtt.Client()
    client.connect(MQTT_BROKER, MQTT_PORT)
    
    # QoS 0 - Fire and forget
    client.publish("test/qos0", "QoS 0 message", qos=0)
    
    # QoS 1 - At least once
    client.publish("test/qos1", "QoS 1 message", qos=1)
    
    # QoS 2 - Exactly once
    client.publish("test/qos2", "QoS 2 message", qos=2)
    
    client.disconnect()

def example_retained_message():
    """Example of retained message"""
    client = mqtt.Client()
    client.connect(MQTT_BROKER, MQTT_PORT)
    
    # Publish retained message (last value kept by broker)
    client.publish("status/online", "1", qos=1, retain=True)
    
    # Clear retained message
    client.publish("status/online", "", qos=1, retain=True)
    
    client.disconnect()

def example_will_message():
    """Example of Last Will and Testament (LWT)"""
    client = mqtt.Client()
    
    # Set will message (published by broker if client disconnects unexpectedly)
    client.will_set("status/python-client", "offline", qos=1, retain=True)
    
    client.connect(MQTT_BROKER, MQTT_PORT)
    
    # Publish online status
    client.publish("status/python-client", "online", qos=1, retain=True)
    
    # ... do work ...
    
    # Clean disconnect (will message NOT sent)
    client.disconnect()

# ============================================================================
# Entry Point
# ============================================================================

if __name__ == "__main__":
    main()
