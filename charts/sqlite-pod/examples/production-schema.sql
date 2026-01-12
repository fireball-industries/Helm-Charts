-- Production Tracking Schema
-- Monitor production runs, quality, downtime, and OEE metrics

-- Production runs
CREATE TABLE IF NOT EXISTS production_runs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  run_id TEXT UNIQUE NOT NULL,
  product_code TEXT NOT NULL,
  product_name TEXT,
  line_id TEXT NOT NULL,
  shift TEXT,
  operator TEXT,
  target_quantity INTEGER,
  produced_quantity INTEGER DEFAULT 0,
  good_quantity INTEGER DEFAULT 0,
  scrap_quantity INTEGER DEFAULT 0,
  rework_quantity INTEGER DEFAULT 0,
  start_time DATETIME,
  end_time DATETIME,
  planned_duration_minutes INTEGER,
  actual_duration_minutes INTEGER,
  status TEXT CHECK(status IN ('scheduled', 'running', 'paused', 'completed', 'aborted')),
  notes TEXT
);

CREATE INDEX idx_runs_line ON production_runs(line_id);
CREATE INDEX idx_runs_product ON production_runs(product_code);
CREATE INDEX idx_runs_start ON production_runs(start_time);
CREATE INDEX idx_runs_status ON production_runs(status);

-- Quality checks
CREATE TABLE IF NOT EXISTS quality_checks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  run_id TEXT NOT NULL,
  sample_id TEXT,
  check_type TEXT NOT NULL,  -- dimensional, visual, functional, etc.
  parameter TEXT NOT NULL,
  measured_value REAL,
  target_value REAL,
  tolerance_min REAL,
  tolerance_max REAL,
  result TEXT CHECK(result IN ('pass', 'fail', 'warning')),
  inspector TEXT,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  notes TEXT,
  FOREIGN KEY (run_id) REFERENCES production_runs(run_id)
);

CREATE INDEX idx_quality_run ON quality_checks(run_id);
CREATE INDEX idx_quality_result ON quality_checks(result);
CREATE INDEX idx_quality_timestamp ON quality_checks(timestamp);

-- Downtime events
CREATE TABLE IF NOT EXISTS downtime_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id TEXT UNIQUE NOT NULL,
  run_id TEXT,
  line_id TEXT NOT NULL,
  category TEXT NOT NULL,  -- mechanical, electrical, material, changeover, etc.
  reason TEXT NOT NULL,
  description TEXT,
  severity TEXT CHECK(severity IN ('minor', 'moderate', 'major', 'critical')),
  start_time DATETIME NOT NULL,
  end_time DATETIME,
  duration_minutes INTEGER,
  resolved_by TEXT,
  resolution TEXT,
  preventive_action TEXT,
  FOREIGN KEY (run_id) REFERENCES production_runs(run_id)
);

CREATE INDEX idx_downtime_line ON downtime_events(line_id);
CREATE INDEX idx_downtime_run ON downtime_events(run_id);
CREATE INDEX idx_downtime_category ON downtime_events(category);
CREATE INDEX idx_downtime_start ON downtime_events(start_time);

-- Shift reports
CREATE TABLE IF NOT EXISTS shift_reports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  report_id TEXT UNIQUE NOT NULL,
  line_id TEXT NOT NULL,
  shift TEXT NOT NULL,
  date DATE NOT NULL,
  operator TEXT,
  supervisor TEXT,
  total_production INTEGER DEFAULT 0,
  total_scrap INTEGER DEFAULT 0,
  total_downtime_minutes INTEGER DEFAULT 0,
  safety_incidents INTEGER DEFAULT 0,
  quality_issues TEXT,
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_shift_reports_line ON shift_reports(line_id);
CREATE INDEX idx_shift_reports_date ON shift_reports(date);
CREATE INDEX idx_shift_reports_shift ON shift_reports(shift);

-- OEE metrics (Overall Equipment Effectiveness)
CREATE TABLE IF NOT EXISTS oee_metrics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  line_id TEXT NOT NULL,
  period TEXT NOT NULL,  -- hour, shift, day, week, month
  start_time DATETIME NOT NULL,
  end_time DATETIME NOT NULL,
  planned_production_time INTEGER,  -- minutes
  downtime INTEGER,  -- minutes
  operating_time INTEGER,  -- minutes
  ideal_cycle_time REAL,  -- minutes per unit
  total_count INTEGER,
  good_count INTEGER,
  availability REAL,  -- %
  performance REAL,  -- %
  quality REAL,  -- %
  oee REAL,  -- %
  calculated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_oee_line ON oee_metrics(line_id);
CREATE INDEX idx_oee_period ON oee_metrics(period);
CREATE INDEX idx_oee_start ON oee_metrics(start_time);

-- Scrap reasons
CREATE TABLE IF NOT EXISTS scrap_reasons (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  run_id TEXT NOT NULL,
  reason_code TEXT NOT NULL,
  reason_description TEXT,
  quantity INTEGER NOT NULL,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (run_id) REFERENCES production_runs(run_id)
);

CREATE INDEX idx_scrap_run ON scrap_reasons(run_id);
CREATE INDEX idx_scrap_reason ON scrap_reasons(reason_code);

-- Sample data
INSERT INTO production_runs (run_id, product_code, product_name, line_id, shift, operator, target_quantity, start_time, status) VALUES
  ('RUN-2026-001', 'PART-A-100', 'Widget Assembly A', 'line-1', 'day', 'John Smith', 1000, datetime('now', '-2 hours'), 'running'),
  ('RUN-2026-002', 'PART-B-200', 'Widget Assembly B', 'line-2', 'day', 'Jane Doe', 500, datetime('now', '-1 hour'), 'running');

INSERT INTO downtime_events (event_id, line_id, category, reason, description, start_time, severity) VALUES
  ('DT-2026-001', 'line-1', 'mechanical', 'Belt slippage', 'Conveyor belt requires adjustment', datetime('now', '-30 minutes'), 'minor'),
  ('DT-2026-002', 'line-2', 'material', 'Material shortage', 'Waiting for raw material delivery', datetime('now', '-45 minutes'), 'moderate');

-- Views
CREATE VIEW current_production AS
SELECT 
  pr.run_id,
  pr.product_code,
  pr.product_name,
  pr.line_id,
  pr.shift,
  pr.operator,
  pr.target_quantity,
  pr.produced_quantity,
  pr.good_quantity,
  pr.scrap_quantity,
  ROUND((pr.good_quantity * 100.0 / NULLIF(pr.produced_quantity, 0)), 2) as yield_pct,
  ROUND((pr.produced_quantity * 100.0 / NULLIF(pr.target_quantity, 0)), 2) as completion_pct,
  pr.start_time,
  ROUND((julianday('now') - julianday(pr.start_time)) * 24 * 60) as runtime_minutes,
  pr.status
FROM production_runs pr
WHERE pr.status IN ('running', 'paused')
ORDER BY pr.start_time;

CREATE VIEW active_downtime AS
SELECT 
  de.event_id,
  de.line_id,
  de.category,
  de.reason,
  de.severity,
  de.start_time,
  ROUND((julianday('now') - julianday(de.start_time)) * 24 * 60) as duration_minutes
FROM downtime_events de
WHERE de.end_time IS NULL
ORDER BY de.start_time;

CREATE VIEW quality_summary AS
SELECT 
  pr.run_id,
  pr.product_code,
  pr.line_id,
  COUNT(qc.id) as total_checks,
  SUM(CASE WHEN qc.result = 'pass' THEN 1 ELSE 0 END) as passed,
  SUM(CASE WHEN qc.result = 'fail' THEN 1 ELSE 0 END) as failed,
  SUM(CASE WHEN qc.result = 'warning' THEN 1 ELSE 0 END) as warnings,
  ROUND((SUM(CASE WHEN qc.result = 'pass' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(qc.id), 0)), 2) as pass_rate_pct
FROM production_runs pr
LEFT JOIN quality_checks qc ON pr.run_id = qc.run_id
GROUP BY pr.run_id, pr.product_code, pr.line_id;

-- Trigger to update run quantities
CREATE TRIGGER update_production_duration
AFTER UPDATE OF end_time ON production_runs
WHEN NEW.end_time IS NOT NULL
BEGIN
  UPDATE production_runs 
  SET actual_duration_minutes = ROUND((julianday(NEW.end_time) - julianday(NEW.start_time)) * 24 * 60)
  WHERE id = NEW.id;
END;

-- Trigger to calculate downtime duration
CREATE TRIGGER update_downtime_duration
AFTER UPDATE OF end_time ON downtime_events
WHEN NEW.end_time IS NOT NULL
BEGIN
  UPDATE downtime_events 
  SET duration_minutes = ROUND((julianday(NEW.end_time) - julianday(NEW.start_time)) * 24 * 60)
  WHERE id = NEW.id;
END;
