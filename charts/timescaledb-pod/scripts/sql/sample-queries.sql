-- TimescaleDB Sample Queries for Industrial IoT/SCADA
-- Because Google-ing "how to query time-series data" at 3 AM is no fun
-- 
-- Pro tip: Replace 'device_id' and date ranges with your actual values
-- Another pro tip: Don't run these on production without a WHERE clause

-- ============================================================================
-- SENSOR DATA QUERIES
-- ============================================================================

-- Get latest value for all sensors on a device
SELECT DISTINCT ON (sensor_type)
  sensor_type,
  time,
  value,
  quality,
  tags
FROM scada_historian.sensor_data
WHERE device_id = 'PLC-001'
ORDER BY sensor_type, time DESC;

-- Average sensor value over the last hour (1-minute buckets)
SELECT
  time_bucket('1 minute', time) AS bucket,
  AVG(value) AS avg_value,
  MIN(value) AS min_value,
  MAX(value) AS max_value
FROM scada_historian.sensor_data
WHERE
  device_id = 'PLC-001'
  AND sensor_type = 'Temperature'
  AND time > NOW() - INTERVAL '1 hour'
GROUP BY bucket
ORDER BY bucket DESC;

-- Find sensors exceeding thresholds (potential alarms)
SELECT
  time,
  device_id,
  sensor_type,
  value
FROM scada_historian.sensor_data
WHERE
  time > NOW() - INTERVAL '24 hours'
  AND (
    (sensor_type = 'Temperature' AND value > 80)
    OR (sensor_type = 'Pressure' AND value > 150)
    OR (sensor_type = 'Vibration' AND value > 5)
  )
ORDER BY time DESC;

-- Downsampled data using TimescaleDB's time_bucket (great for charts)
SELECT
  time_bucket('5 minutes', time) AS bucket,
  device_id,
  sensor_type,
  AVG(value) AS avg,
  first(value, time) AS first_value,
  last(value, time) AS last_value
FROM scada_historian.sensor_data
WHERE
  time BETWEEN '2026-01-01' AND '2026-01-11'
GROUP BY bucket, device_id, sensor_type
ORDER BY bucket, device_id, sensor_type;

-- ============================================================================
-- PRODUCTION METRICS QUERIES
-- ============================================================================

-- OEE Calculation (Overall Equipment Effectiveness)
-- OEE = Availability × Performance × Quality
SELECT
  line_id,
  product_id,
  DATE(time) AS production_date,
  SUM(good_count + scrap_count + rework_count) AS total_count,
  SUM(good_count) AS good_count,
  SUM(scrap_count) AS scrap_count,
  -- Availability (assuming 8-hour shift = 480 minutes)
  100.0 * (480 - SUM(downtime_minutes)) / 480 AS availability_percent,
  -- Quality (First Pass Yield)
  100.0 * SUM(good_count) / NULLIF(SUM(good_count + scrap_count), 0) AS quality_percent,
  -- Simplified OEE (would need cycle time for true performance)
  (
    ((480 - SUM(downtime_minutes)) / 480.0) *
    (SUM(good_count) / NULLIF(SUM(good_count + scrap_count), 0.0))
  ) * 100 AS simplified_oee_percent
FROM production_metrics.production_counts
WHERE
  time >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY line_id, product_id, DATE(time)
ORDER BY production_date DESC, line_id;

-- Downtime analysis by line
SELECT
  line_id,
  DATE(time) AS date,
  SUM(downtime_minutes) AS total_downtime,
  COUNT(*) AS occurrence_count,
  AVG(downtime_minutes) AS avg_downtime_per_occurrence
FROM production_metrics.production_counts
WHERE
  time >= CURRENT_DATE - INTERVAL '30 days'
  AND downtime_minutes > 0
GROUP BY line_id, DATE(time)
ORDER BY total_downtime DESC;

-- Shift performance comparison
SELECT
  shift,
  COUNT(DISTINCT line_id) AS lines_operated,
  SUM(good_count) AS total_good,
  SUM(scrap_count) AS total_scrap,
  100.0 * SUM(good_count) / NULLIF(SUM(good_count + scrap_count), 0) AS yield_percent,
  SUM(downtime_minutes) AS total_downtime
FROM production_metrics.production_counts
WHERE
  time >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY shift
ORDER BY yield_percent DESC;

-- ============================================================================
-- ENERGY MANAGEMENT QUERIES
-- ============================================================================

-- Daily energy consumption trend
SELECT
  DATE(time) AS date,
  meter_id,
  SUM(kwh) AS total_kwh,
  MAX(kw_demand) AS peak_demand,
  AVG(power_factor) AS avg_power_factor
FROM energy_management.energy_consumption
WHERE
  time >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(time), meter_id
ORDER BY date DESC, meter_id;

-- Find demand peaks (for demand charge optimization)
SELECT
  time,
  meter_id,
  kw_demand,
  kwh
FROM energy_management.energy_consumption
WHERE
  time >= CURRENT_DATE - INTERVAL '30 days'
  AND kw_demand > (
    SELECT AVG(kw_demand) * 1.5
    FROM energy_management.energy_consumption
    WHERE meter_id = energy_management.energy_consumption.meter_id
  )
ORDER BY kw_demand DESC
LIMIT 100;

-- Energy cost calculation (assuming time-of-use rates)
SELECT
  DATE(time) AS date,
  meter_id,
  SUM(CASE
    WHEN EXTRACT(HOUR FROM time) BETWEEN 6 AND 22 THEN kwh * 0.12  -- Peak rate
    ELSE kwh * 0.06  -- Off-peak rate
  END) AS estimated_energy_cost,
  MAX(kw_demand) * 15.00 AS estimated_demand_charge,  -- $15/kW
  SUM(CASE
    WHEN EXTRACT(HOUR FROM time) BETWEEN 6 AND 22 THEN kwh * 0.12
    ELSE kwh * 0.06
  END) + (MAX(kw_demand) * 15.00) AS total_estimated_cost
FROM energy_management.energy_consumption
WHERE
  time >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(time), meter_id
ORDER BY total_estimated_cost DESC;

-- ============================================================================
-- QUALITY DATA QUERIES
-- ============================================================================

-- SPC (Statistical Process Control) - Control chart data
WITH stats AS (
  SELECT
    measurement_type,
    AVG(value) AS mean,
    STDDEV(value) AS stddev
  FROM quality_data.quality_measurements
  WHERE
    time >= CURRENT_DATE - INTERVAL '30 days'
    AND passed = TRUE  -- Only use good parts for limits
  GROUP BY measurement_type
)
SELECT
  qm.time,
  qm.measurement_type,
  qm.value,
  s.mean,
  s.mean + (3 * s.stddev) AS ucl,  -- Upper Control Limit
  s.mean - (3 * s.stddev) AS lcl,  -- Lower Control Limit
  qm.usl,  -- Upper Spec Limit
  qm.lsl,  -- Lower Spec Limit
  CASE
    WHEN qm.value > s.mean + (3 * s.stddev) THEN 'Above UCL'
    WHEN qm.value < s.mean - (3 * s.stddev) THEN 'Below LCL'
    WHEN qm.value > s.mean + (2 * s.stddev) THEN 'Warning High'
    WHEN qm.value < s.mean - (2 * s.stddev) THEN 'Warning Low'
    ELSE 'In Control'
  END AS control_status
FROM quality_data.quality_measurements qm
JOIN stats s ON qm.measurement_type = s.measurement_type
WHERE
  qm.time >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY qm.time DESC;

-- Cpk Calculation (Process Capability)
SELECT
  measurement_type,
  AVG(value) AS mean,
  STDDEV(value) AS stddev,
  MAX(usl) AS usl,
  MAX(lsl) AS lsl,
  -- Cpk formula
  LEAST(
    (MAX(usl) - AVG(value)) / (3 * STDDEV(value)),
    (AVG(value) - MAX(lsl)) / (3 * STDDEV(value))
  ) AS cpk,
  CASE
    WHEN LEAST(
      (MAX(usl) - AVG(value)) / (3 * STDDEV(value)),
      (AVG(value) - MAX(lsl)) / (3 * STDDEV(value))
    ) >= 1.33 THEN 'Capable'
    WHEN LEAST(
      (MAX(usl) - AVG(value)) / (3 * STDDEV(value)),
      (AVG(value) - MAX(lsl)) / (3 * STDDEV(value))
    ) >= 1.00 THEN 'Marginal'
    ELSE 'Not Capable'
  END AS capability_status
FROM quality_data.quality_measurements
WHERE
  time >= CURRENT_DATE - INTERVAL '30 days'
  AND usl IS NOT NULL
  AND lsl IS NOT NULL
GROUP BY measurement_type;

-- ============================================================================
-- ALARM ANALYSIS QUERIES
-- ============================================================================

-- Top alarms by frequency
SELECT
  alarm_id,
  device_id,
  severity,
  COUNT(*) AS occurrence_count,
  MAX(time) AS last_occurrence,
  AVG(EXTRACT(EPOCH FROM (acknowledged_at - time))) AS avg_ack_time_seconds
FROM scada_historian.alarm_history
WHERE
  time >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY alarm_id, device_id, severity
ORDER BY occurrence_count DESC
LIMIT 20;

-- Unacknowledged alarms (current active)
SELECT
  time,
  alarm_id,
  device_id,
  severity,
  message,
  EXTRACT(EPOCH FROM (NOW() - time))/60 AS minutes_active
FROM scada_historian.alarm_history
WHERE
  acknowledged = FALSE
ORDER BY
  CASE severity
    WHEN 'critical' THEN 1
    WHEN 'high' THEN 2
    WHEN 'medium' THEN 3
    WHEN 'low' THEN 4
    ELSE 5
  END,
  time ASC;

-- Alarm response time analysis
SELECT
  device_id,
  severity,
  COUNT(*) AS total_alarms,
  AVG(EXTRACT(EPOCH FROM (acknowledged_at - time))/60) AS avg_response_minutes,
  MAX(EXTRACT(EPOCH FROM (acknowledged_at - time))/60) AS max_response_minutes,
  MIN(EXTRACT(EPOCH FROM (acknowledged_at - time))/60) AS min_response_minutes
FROM scada_historian.alarm_history
WHERE
  time >= CURRENT_DATE - INTERVAL '30 days'
  AND acknowledged = TRUE
GROUP BY device_id, severity
ORDER BY avg_response_minutes DESC;

-- ============================================================================
-- CONTINUOUS AGGREGATE QUERIES (Pre-computed rollups)
-- ============================================================================

-- Query hourly sensor rollup (much faster than raw data)
SELECT
  bucket,
  device_id,
  sensor_type,
  avg_value,
  min_value,
  max_value,
  sample_count
FROM sensor_data_hourly
WHERE
  bucket >= NOW() - INTERVAL '7 days'
  AND device_id = 'PLC-001'
ORDER BY bucket DESC;

-- Daily production summary (pre-aggregated)
SELECT
  bucket AS date,
  line_id,
  product_id,
  total_good,
  total_scrap,
  yield_percent,
  total_downtime
FROM production_daily
WHERE
  bucket >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY bucket DESC, line_id;

-- Monthly energy costs
SELECT
  bucket AS month,
  meter_id,
  total_kwh,
  peak_demand,
  avg_power_factor,
  total_kwh * 0.10 AS estimated_energy_cost,  -- $0.10/kWh
  peak_demand * 15.00 AS estimated_demand_charge  -- $15/kW
FROM energy_monthly
ORDER BY bucket DESC;

-- ============================================================================
-- DATABASE MAINTENANCE & MONITORING QUERIES
-- ============================================================================

-- Check hypertable sizes and compression ratios
SELECT
  hypertable_schema,
  hypertable_name,
  pg_size_pretty(total_bytes) AS total_size,
  pg_size_pretty(before_compression_total_bytes) AS before_compression,
  pg_size_pretty(after_compression_total_bytes) AS after_compression,
  CASE
    WHEN before_compression_total_bytes > 0 THEN
      ROUND(100 * (1 - after_compression_total_bytes::NUMERIC / before_compression_total_bytes), 2)
    ELSE 0
  END AS compression_ratio_percent
FROM timescaledb_information.hypertables h
LEFT JOIN LATERAL hypertable_size(format('%I.%I', hypertable_schema, hypertable_name)) total_bytes ON true
LEFT JOIN LATERAL hypertable_compression_stats(format('%I.%I', hypertable_schema, hypertable_name)) ON true
ORDER BY total_bytes DESC;

-- Check chunk distribution
SELECT
  hypertable_name,
  COUNT(*) AS chunk_count,
  pg_size_pretty(SUM(total_bytes)) AS total_size,
  MIN(range_start) AS oldest_chunk,
  MAX(range_end) AS newest_chunk
FROM timescaledb_information.chunks
GROUP BY hypertable_name
ORDER BY chunk_count DESC;

-- Background job status
SELECT
  job_id,
  application_name,
  schedule_interval,
  job_status,
  last_run_status,
  next_start,
  total_runs,
  total_successes,
  total_failures
FROM timescaledb_information.jobs
ORDER BY job_id;

-- Find slow queries (requires pg_stat_statements)
SELECT
  SUBSTRING(query, 1, 100) AS query_preview,
  calls,
  ROUND(total_exec_time::NUMERIC, 2) AS total_time_ms,
  ROUND(mean_exec_time::NUMERIC, 2) AS avg_time_ms,
  ROUND(max_exec_time::NUMERIC, 2) AS max_time_ms
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY mean_exec_time DESC
LIMIT 20;

-- ============================================================================
-- ADVANCED TIMESCALEDB FUNCTIONS
-- ============================================================================

-- Gap filling (insert NULL for missing time buckets)
SELECT
  time_bucket_gapfill('1 hour', time) AS bucket,
  device_id,
  AVG(value) AS avg_value,
  interpolate(AVG(value)) AS interpolated_value  -- Fill gaps with interpolation
FROM scada_historian.sensor_data
WHERE
  time >= NOW() - INTERVAL '24 hours'
  AND device_id = 'PLC-001'
  AND sensor_type = 'Temperature'
GROUP BY bucket, device_id;

-- Histogram (value distribution)
SELECT
  histogram(value, 0, 100, 10) AS value_histogram
FROM scada_historian.sensor_data
WHERE
  sensor_type = 'Temperature'
  AND time >= NOW() - INTERVAL '7 days';

-- LOCF (Last Observation Carried Forward)
SELECT
  time_bucket_gapfill('5 minutes', time) AS bucket,
  device_id,
  sensor_type,
  locf(AVG(value)) AS value_locf
FROM scada_historian.sensor_data
WHERE
  time >= NOW() - INTERVAL '1 hour'
  AND device_id = 'PLC-001'
GROUP BY bucket, device_id, sensor_type;

-- ===========================================================================
-- NOTES
-- ===========================================================================
-- 
-- Performance Tips:
-- 1. Always include time bounds in WHERE clauses
-- 2. Use continuous aggregates for frequently-accessed historical data
-- 3. Leverage time_bucket for downsampling instead of GROUP BY date
-- 4. Create indexes on commonly-filtered columns (device_id, sensor_type, etc.)
-- 5. Use EXPLAIN ANALYZE to check query plans
--
-- TimescaleDB-Specific:
-- - first(value, time) / last(value, time) are aggregates for time-series
-- - time_bucket_gapfill() for filling missing time intervals
-- - interpolate() and locf() for gap filling strategies
-- - histogram() for value distribution analysis
--
-- Remember: Your SCADA system doesn't take coffee breaks, so your queries
-- shouldn't either. Keep them fast, focused, and time-bounded.
--
-- Pro tip: If a query takes longer than your coffee break, it's time to add
-- an index or use a continuous aggregate. Your future self will thank you.
