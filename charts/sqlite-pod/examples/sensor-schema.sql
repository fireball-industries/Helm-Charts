-- Sensor Data Schema
-- Industrial sensor data collection and monitoring

-- Sensor registry
CREATE TABLE IF NOT EXISTS sensors (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sensor_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,  -- temperature, pressure, speed, etc.
  location TEXT,
  unit TEXT,
  min_value REAL,
  max_value REAL,
  description TEXT,
  enabled BOOLEAN DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sensors_location ON sensors(location);
CREATE INDEX idx_sensors_type ON sensors(type);
CREATE INDEX idx_sensors_enabled ON sensors(enabled);

-- Sensor readings (time-series data)
CREATE TABLE IF NOT EXISTS sensor_readings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sensor_id TEXT NOT NULL,
  value REAL NOT NULL,
  unit TEXT,
  quality INTEGER DEFAULT 192,  -- OPC-UA quality code (192 = good)
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  synced BOOLEAN DEFAULT 0,  -- Synced to cloud/InfluxDB
  FOREIGN KEY (sensor_id) REFERENCES sensors(sensor_id)
);

CREATE INDEX idx_readings_sensor ON sensor_readings(sensor_id);
CREATE INDEX idx_readings_timestamp ON sensor_readings(timestamp);
CREATE INDEX idx_readings_synced ON sensor_readings(synced);
CREATE INDEX idx_readings_sensor_time ON sensor_readings(sensor_id, timestamp);

-- Sensor events (alerts, anomalies)
CREATE TABLE IF NOT EXISTS sensor_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sensor_id TEXT NOT NULL,
  event_type TEXT NOT NULL,  -- threshold_exceeded, anomaly, offline, restored
  severity TEXT CHECK(severity IN ('info', 'warning', 'error', 'critical')),
  message TEXT,
  value REAL,
  threshold REAL,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  acknowledged BOOLEAN DEFAULT 0,
  acknowledged_by TEXT,
  acknowledged_at DATETIME,
  FOREIGN KEY (sensor_id) REFERENCES sensors(sensor_id)
);

CREATE INDEX idx_events_sensor ON sensor_events(sensor_id);
CREATE INDEX idx_events_timestamp ON sensor_events(timestamp);
CREATE INDEX idx_events_severity ON sensor_events(severity);
CREATE INDEX idx_events_acknowledged ON sensor_events(acknowledged);

-- Sensor statistics (aggregated data)
CREATE TABLE IF NOT EXISTS sensor_statistics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sensor_id TEXT NOT NULL,
  period TEXT NOT NULL,  -- hour, day, week, month
  avg_value REAL,
  min_value REAL,
  max_value REAL,
  sample_count INTEGER,
  start_time DATETIME NOT NULL,
  end_time DATETIME NOT NULL,
  FOREIGN KEY (sensor_id) REFERENCES sensors(sensor_id)
);

CREATE INDEX idx_stats_sensor ON sensor_statistics(sensor_id);
CREATE INDEX idx_stats_period ON sensor_statistics(period);
CREATE INDEX idx_stats_start ON sensor_statistics(start_time);

-- Sample data
INSERT INTO sensors (sensor_id, name, type, location, unit, min_value, max_value) VALUES
  ('temp-01', 'Line 1 Temperature', 'temperature', 'line-1', 'F', 32, 212),
  ('temp-02', 'Line 2 Temperature', 'temperature', 'line-2', 'F', 32, 212),
  ('pressure-01', 'Line 1 Pressure', 'pressure', 'line-1', 'PSI', 0, 150),
  ('speed-01', 'Motor 1 Speed', 'speed', 'line-1', 'RPM', 0, 3600),
  ('vibration-01', 'Pump 1 Vibration', 'vibration', 'utilities', 'mm/s', 0, 10);

-- Trigger to update updated_at timestamp
CREATE TRIGGER update_sensor_timestamp 
AFTER UPDATE ON sensors
BEGIN
  UPDATE sensors SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;
