/**
 * Mosquitto MQTT Broker - Node.js Client Example
 * Using MQTT.js library
 * 
 * Install: npm install mqtt
 * 
 * Author: Patrick Ryan - Fireball Industries
 */

const mqtt = require('mqtt');

// ============================================================================
// Configuration
// ============================================================================

const config = {
  broker: 'mqtt://mosquitto.iot.svc.cluster.local:1883',
  // For TLS: 'mqtts://mosquitto.iot.svc.cluster.local:8883'
  // For WebSocket: 'ws://mosquitto.iot.svc.cluster.local:9001'
  
  options: {
    clientId: 'nodejs-example-01',
    clean: true,
    connectTimeout: 4000,
    reconnectPeriod: 1000,
    
    // Authentication (comment out if not needed)
    username: 'sensor01',
    password: 'secret123',
    
    // Last Will and Testament
    will: {
      topic: 'status/nodejs-client',
      payload: 'offline',
      qos: 1,
      retain: true
    }
    
    // For TLS, add:
    // ca: fs.readFileSync('ca.crt'),
    // cert: fs.readFileSync('client.crt'),
    // key: fs.readFileSync('client.key'),
    // rejectUnauthorized: true
  },
  
  publishTopic: 'sensors/nodejs-example/data',
  subscribeTopic: 'sensors/#'
};

// ============================================================================
// Main Application
// ============================================================================

console.log('🦟 Mosquitto MQTT - Node.js Client Example');
console.log('   Fireball Industries - Patrick Ryan\n');

// Connect to MQTT broker
console.log(`🔌 Connecting to ${config.broker}...`);
const client = mqtt.connect(config.broker, config.options);

// ============================================================================
// Event Handlers
// ============================================================================

// Connection event
client.on('connect', () => {
  console.log(`✅ Connected to MQTT broker`);
  console.log(`   Client ID: ${config.options.clientId}`);
  
  // Publish online status
  client.publish('status/nodejs-client', 'online', { qos: 1, retain: true });
  
  // Subscribe to topics
  client.subscribe(config.subscribeTopic, { qos: 1 }, (err, granted) => {
    if (err) {
      console.error(`❌ Subscribe error: ${err.message}`);
    } else {
      console.log(`📡 Subscribed to: ${config.subscribeTopic}`);
      console.log(`   QoS: ${granted[0].qos}`);
    }
  });
  
  // Start publishing messages
  startPublishing();
});

// Message received event
client.on('message', (topic, message, packet) => {
  console.log(`\n📥 Message received:`);
  console.log(`   Topic: ${topic}`);
  console.log(`   QoS: ${packet.qos}`);
  console.log(`   Retained: ${packet.retain}`);
  
  // Try to parse JSON
  try {
    const payload = JSON.parse(message.toString());
    console.log(`   Payload: ${JSON.stringify(payload, null, 2)}`);
  } catch (e) {
    console.log(`   Payload: ${message.toString()}`);
  }
});

// Error event
client.on('error', (error) => {
  console.error(`❌ Connection error: ${error.message}`);
});

// Reconnect event
client.on('reconnect', () => {
  console.log('🔄 Reconnecting to broker...');
});

// Disconnect event
client.on('close', () => {
  console.log('👋 Disconnected from broker');
});

// Offline event
client.on('offline', () => {
  console.log('⚠️  Client is offline');
});

// ============================================================================
// Publishing Logic
// ============================================================================

let messageCounter = 0;
let publishInterval;

function startPublishing() {
  console.log('\n📤 Publishing messages (Ctrl+C to stop)...\n');
  
  publishInterval = setInterval(() => {
    messageCounter++;
    
    // Create sensor data
    const payload = {
      sensor_id: 'nodejs-example-01',
      timestamp: new Date().toISOString(),
      temperature: 20.0 + (messageCounter % 10),
      humidity: 50.0 + (messageCounter % 20),
      counter: messageCounter
    };
    
    // Publish message
    client.publish(
      config.publishTopic,
      JSON.stringify(payload),
      { qos: 1, retain: false },
      (err) => {
        if (err) {
          console.error(`❌ Publish error: ${err.message}`);
        } else {
          console.log(`📤 Published message #${messageCounter}`);
        }
      }
    );
  }, 5000); // Every 5 seconds
}

// ============================================================================
// Graceful Shutdown
// ============================================================================

process.on('SIGINT', () => {
  console.log('\n⏹️  Stopping...');
  
  // Clear interval
  if (publishInterval) {
    clearInterval(publishInterval);
  }
  
  // Publish offline status
  client.publish(
    'status/nodejs-client',
    'offline',
    { qos: 1, retain: true },
    () => {
      // Disconnect gracefully
      client.end(false, () => {
        console.log('👋 Goodbye!');
        process.exit(0);
      });
    }
  );
});

// ============================================================================
// Additional Examples
// ============================================================================

/**
 * Example: QoS Levels
 */
function exampleQoSLevels() {
  // QoS 0 - Fire and forget
  client.publish('test/qos0', 'QoS 0 message', { qos: 0 });
  
  // QoS 1 - At least once
  client.publish('test/qos1', 'QoS 1 message', { qos: 1 });
  
  // QoS 2 - Exactly once
  client.publish('test/qos2', 'QoS 2 message', { qos: 2 });
}

/**
 * Example: Retained Messages
 */
function exampleRetainedMessage() {
  // Publish retained message (last value kept by broker)
  client.publish('status/online', '1', { qos: 1, retain: true });
  
  // Clear retained message (publish empty with retain flag)
  client.publish('status/online', '', { qos: 1, retain: true });
}

/**
 * Example: Wildcard Subscriptions
 */
function exampleWildcardSubscriptions() {
  // Single level wildcard (+)
  client.subscribe('sensors/+/temperature');
  // Receives: sensors/sensor01/temperature, sensors/sensor02/temperature
  
  // Multi-level wildcard (#)
  client.subscribe('factory/#');
  // Receives: factory/line1/status, factory/line1/machine1/temp, etc.
  
  // Multiple topics
  client.subscribe(['sensors/+/temp', 'alarms/#', 'status/+']);
}

/**
 * Example: Bulk Publishing
 */
async function exampleBulkPublish() {
  const messages = [
    { topic: 'sensors/temp01', payload: '25.5' },
    { topic: 'sensors/temp02', payload: '26.1' },
    { topic: 'sensors/humidity01', payload: '55.2' }
  ];
  
  for (const msg of messages) {
    await new Promise((resolve, reject) => {
      client.publish(msg.topic, msg.payload, { qos: 1 }, (err) => {
        if (err) reject(err);
        else resolve();
      });
    });
  }
}

/**
 * Example: Request-Response Pattern
 */
function exampleRequestResponse() {
  const requestTopic = 'request/sensor01/status';
  const responseTopic = 'response/sensor01/status';
  
  // Subscribe to response
  client.subscribe(responseTopic);
  
  // Send request
  client.publish(requestTopic, JSON.stringify({ action: 'get_status' }), { qos: 1 });
  
  // Handle response
  client.on('message', (topic, message) => {
    if (topic === responseTopic) {
      const response = JSON.parse(message.toString());
      console.log('Response received:', response);
    }
  });
}

/**
 * Example: Sparkplug B Message
 */
function exampleSparkplugB() {
  const namespace = 'spBv1.0';
  const groupId = 'Factory';
  const edgeNodeId = 'Edge-01';
  
  // NBIRTH message
  const nbirth = {
    timestamp: Date.now(),
    metrics: [
      { name: 'Node Control/Rebirth', type: 'Boolean', value: false },
      { name: 'Properties/Version', type: 'String', value: '1.0.0' }
    ],
    seq: 0
  };
  
  client.publish(
    `${namespace}/${groupId}/NBIRTH/${edgeNodeId}`,
    JSON.stringify(nbirth),
    { qos: 1 }
  );
  
  // NDATA message
  const ndata = {
    timestamp: Date.now(),
    metrics: [
      { name: 'Temperature', type: 'Float', value: 25.5 }
    ],
    seq: 1
  };
  
  client.publish(
    `${namespace}/${groupId}/NDATA/${edgeNodeId}`,
    JSON.stringify(ndata),
    { qos: 0 }
  );
}

// ============================================================================
// Module Exports (if used as library)
// ============================================================================

module.exports = {
  client,
  exampleQoSLevels,
  exampleRetainedMessage,
  exampleWildcardSubscriptions,
  exampleBulkPublish,
  exampleRequestResponse,
  exampleSparkplugB
};
