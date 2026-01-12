-- Equipment Maintenance Schema
-- Track equipment, maintenance schedules, work orders, and parts

-- Equipment registry
CREATE TABLE IF NOT EXISTS equipment (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  equipment_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,  -- motor, pump, conveyor, robot, etc.
  manufacturer TEXT,
  model TEXT,
  serial_number TEXT,
  location TEXT,
  installation_date DATE,
  warranty_expiry DATE,
  status TEXT CHECK(status IN ('active', 'maintenance', 'down', 'retired')),
  criticality TEXT CHECK(criticality IN ('low', 'medium', 'high', 'critical')),
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_equipment_location ON equipment(location);
CREATE INDEX idx_equipment_status ON equipment(status);
CREATE INDEX idx_equipment_criticality ON equipment(criticality);

-- Maintenance schedules (preventive maintenance)
CREATE TABLE IF NOT EXISTS maintenance_schedules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  equipment_id TEXT NOT NULL,
  task_name TEXT NOT NULL,
  description TEXT,
  frequency_days INTEGER NOT NULL,  -- Days between maintenance
  last_performed DATE,
  next_due DATE,
  estimated_hours REAL,
  priority INTEGER DEFAULT 3,
  enabled BOOLEAN DEFAULT 1,
  FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id)
);

CREATE INDEX idx_schedules_equipment ON maintenance_schedules(equipment_id);
CREATE INDEX idx_schedules_next_due ON maintenance_schedules(next_due);
CREATE INDEX idx_schedules_enabled ON maintenance_schedules(enabled);

-- Work orders
CREATE TABLE IF NOT EXISTS work_orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  work_order_id TEXT UNIQUE NOT NULL,
  equipment_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  type TEXT CHECK(type IN ('preventive', 'corrective', 'inspection', 'upgrade')),
  priority TEXT CHECK(priority IN ('low', 'medium', 'high', 'urgent')),
  status TEXT CHECK(status IN ('pending', 'assigned', 'in-progress', 'completed', 'cancelled')),
  assigned_to TEXT,
  requested_by TEXT,
  estimated_hours REAL,
  actual_hours REAL,
  parts_cost REAL DEFAULT 0,
  labor_cost REAL DEFAULT 0,
  requested_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  scheduled_date DATETIME,
  started_date DATETIME,
  completed_date DATETIME,
  notes TEXT,
  FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id)
);

CREATE INDEX idx_workorders_equipment ON work_orders(equipment_id);
CREATE INDEX idx_workorders_status ON work_orders(status);
CREATE INDEX idx_workorders_priority ON work_orders(priority);
CREATE INDEX idx_workorders_assigned ON work_orders(assigned_to);
CREATE INDEX idx_workorders_scheduled ON work_orders(scheduled_date);

-- Parts inventory
CREATE TABLE IF NOT EXISTS parts_inventory (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  part_number TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  manufacturer TEXT,
  unit_cost REAL,
  quantity_on_hand INTEGER DEFAULT 0,
  min_quantity INTEGER DEFAULT 0,
  max_quantity INTEGER,
  location TEXT,
  last_ordered DATE,
  supplier TEXT,
  notes TEXT
);

CREATE INDEX idx_parts_category ON parts_inventory(category);
CREATE INDEX idx_parts_low_stock ON parts_inventory(quantity_on_hand);

-- Work order parts (parts used in work orders)
CREATE TABLE IF NOT EXISTS work_order_parts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  work_order_id TEXT NOT NULL,
  part_number TEXT NOT NULL,
  quantity_used INTEGER NOT NULL,
  unit_cost REAL,
  FOREIGN KEY (work_order_id) REFERENCES work_orders(work_order_id),
  FOREIGN KEY (part_number) REFERENCES parts_inventory(part_number)
);

CREATE INDEX idx_wo_parts_workorder ON work_order_parts(work_order_id);
CREATE INDEX idx_wo_parts_part ON work_order_parts(part_number);

-- Maintenance history
CREATE TABLE IF NOT EXISTS maintenance_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  equipment_id TEXT NOT NULL,
  work_order_id TEXT,
  maintenance_type TEXT,
  description TEXT,
  performed_by TEXT,
  performed_date DATETIME,
  duration_hours REAL,
  parts_replaced TEXT,
  observations TEXT,
  FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id),
  FOREIGN KEY (work_order_id) REFERENCES work_orders(work_order_id)
);

CREATE INDEX idx_history_equipment ON maintenance_history(equipment_id);
CREATE INDEX idx_history_date ON maintenance_history(performed_date);

-- Sample data
INSERT INTO equipment (equipment_id, name, type, manufacturer, location, status, criticality) VALUES
  ('motor-001', 'Conveyor Motor 1', 'motor', 'ABB', 'line-1', 'active', 'high'),
  ('pump-001', 'Hydraulic Pump 1', 'pump', 'Rexroth', 'utilities', 'active', 'critical'),
  ('robot-001', 'Assembly Robot 1', 'robot', 'FANUC', 'line-2', 'active', 'critical'),
  ('conveyor-001', 'Main Conveyor', 'conveyor', 'Dorner', 'line-1', 'active', 'medium');

INSERT INTO maintenance_schedules (equipment_id, task_name, description, frequency_days, estimated_hours) VALUES
  ('motor-001', 'Lubrication', 'Lubricate bearings and check alignment', 30, 0.5),
  ('motor-001', 'Inspection', 'Visual inspection and vibration analysis', 90, 1.0),
  ('pump-001', 'Filter Change', 'Replace hydraulic filter', 180, 1.5),
  ('robot-001', 'Calibration', 'Recalibrate positioning system', 90, 2.0);

INSERT INTO parts_inventory (part_number, name, category, unit_cost, quantity_on_hand, min_quantity) VALUES
  ('BEARING-6205', 'Deep Groove Ball Bearing 6205', 'bearings', 12.50, 10, 5),
  ('FILTER-HF35', 'Hydraulic Filter HF35', 'filters', 45.00, 3, 2),
  ('GREASE-EP2', 'EP2 Lithium Grease', 'lubricants', 8.00, 20, 10),
  ('BELT-V100', 'V-Belt 100 inch', 'belts', 25.00, 5, 3);

-- Triggers
CREATE TRIGGER update_equipment_timestamp 
AFTER UPDATE ON equipment
BEGIN
  UPDATE equipment SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- View: Upcoming maintenance
CREATE VIEW upcoming_maintenance AS
SELECT 
  ms.id,
  e.equipment_id,
  e.name as equipment_name,
  e.location,
  ms.task_name,
  ms.next_due,
  ms.estimated_hours,
  julianday(ms.next_due) - julianday('now') as days_until_due
FROM maintenance_schedules ms
JOIN equipment e ON ms.equipment_id = e.equipment_id
WHERE ms.enabled = 1 AND ms.next_due IS NOT NULL
ORDER BY ms.next_due;

-- View: Low stock parts
CREATE VIEW low_stock_parts AS
SELECT 
  part_number,
  name,
  category,
  quantity_on_hand,
  min_quantity,
  (min_quantity - quantity_on_hand) as reorder_qty
FROM parts_inventory
WHERE quantity_on_hand <= min_quantity
ORDER BY (min_quantity - quantity_on_hand) DESC;
