-- ============================================================================
-- Blood Bank & Emergency Donor-Matching System
-- Reusable SQL Views — PostgreSQL
-- ============================================================================
-- DEPENDENCY: Execute schema.sql → triggers.sql → procedures.sql → seed.sql
--
-- All views use CREATE OR REPLACE VIEW (idempotent).
-- Materialized views use CREATE MATERIALIZED VIEW IF NOT EXISTS +
--   a REFRESH command.
-- ============================================================================


-- ────────────────────────────────────────────────────────────────────────────
-- 0. CLEAN SLATE — drop materialized views (cannot use CREATE OR REPLACE)
-- ────────────────────────────────────────────────────────────────────────────
DROP MATERIALIZED VIEW IF EXISTS mv_inventory_dashboard CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mv_monthly_report      CASCADE;


-- ============================================================================
-- VIEW 1: vw_available_inventory
-- Real-time count of available (non-expired) blood units by blood type.
-- Joins blood_units → donors to resolve blood type (3NF).
-- ============================================================================
CREATE OR REPLACE VIEW vw_available_inventory AS
SELECT d.blood_group,
       d.rh_factor,
       COUNT(*)                    AS available_units,
       SUM(bu.volume_ml)           AS total_volume_ml,
       MIN(bu.expiration_date)     AS earliest_expiry,
       MAX(bu.expiration_date)     AS latest_expiry,
       MIN(bu.expiration_date) - CURRENT_DATE AS days_to_earliest_expiry
FROM   blood_units bu
INNER JOIN donors d ON d.donor_id = bu.donor_id
WHERE  bu.status           = 'AVAILABLE'
  AND  bu.expiration_date >= CURRENT_DATE
GROUP BY d.blood_group, d.rh_factor
ORDER BY d.blood_group, d.rh_factor;

COMMENT ON VIEW vw_available_inventory IS
    'Real-time available blood inventory grouped by blood type. '
    'Excludes expired units. Resolves blood type via donor join (3NF).';


-- ============================================================================
-- VIEW 2: vw_hospital_statistics
-- Per-hospital request counts, fulfillment rates, and demand totals.
-- ============================================================================
CREATE OR REPLACE VIEW vw_hospital_statistics AS
SELECT h.hospital_id,
       h.name                                                                  AS hospital_name,
       h.priority_level,
       h.is_active,
       COUNT(br.request_id)                                                    AS total_requests,
       SUM(br.quantity)                                                        AS total_units_requested,
       COUNT(*) FILTER (WHERE br.fulfillment_status = 'FULFILLED')             AS fulfilled,
       COUNT(*) FILTER (WHERE br.fulfillment_status = 'PARTIAL')               AS partial,
       COUNT(*) FILTER (WHERE br.fulfillment_status = 'PENDING')               AS pending,
       COUNT(*) FILTER (WHERE br.fulfillment_status = 'CANCELLED')             AS cancelled,
       ROUND(
           COUNT(*) FILTER (WHERE br.fulfillment_status = 'FULFILLED') * 100.0
           / NULLIF(COUNT(br.request_id), 0), 1
       ) AS fulfillment_pct
FROM   hospitals h
LEFT JOIN blood_requests br ON br.hospital_id = h.hospital_id
GROUP BY h.hospital_id, h.name, h.priority_level, h.is_active
ORDER BY total_requests DESC;

COMMENT ON VIEW vw_hospital_statistics IS
    'Per-hospital statistics: request counts by fulfillment status, '
    'total demand, and fulfillment percentage.';


-- ============================================================================
-- VIEW 3: vw_monthly_donations
-- Monthly aggregation of blood unit collections.
-- ============================================================================
CREATE OR REPLACE VIEW vw_monthly_donations AS
SELECT date_trunc('month', bu.collection_date)::DATE AS month,
       COUNT(*)                                       AS units_collected,
       COUNT(DISTINCT bu.donor_id)                    AS unique_donors,
       SUM(bu.volume_ml)                              AS total_volume_ml,
       ROUND(AVG(bu.volume_ml)::NUMERIC, 1)           AS avg_volume_ml
FROM   blood_units bu
GROUP BY date_trunc('month', bu.collection_date)
ORDER BY month DESC;

COMMENT ON VIEW vw_monthly_donations IS
    'Monthly blood donation report: units collected, unique donors, '
    'and volume statistics.';


-- ============================================================================
-- VIEW 4: vw_donor_statistics
-- Per-donor donation history, activity status, and ranking.
-- ============================================================================
CREATE OR REPLACE VIEW vw_donor_statistics AS
SELECT d.donor_id,
       d.first_name || ' ' || d.last_name  AS donor_name,
       d.blood_group,
       d.rh_factor,
       d.phone,
       d.email,
       d.is_active,
       d.registered_at,
       COUNT(bu.unit_id)                    AS total_donations,
       MAX(bu.collection_date)              AS last_donation_date,
       MIN(bu.collection_date)              AS first_donation_date,
       CASE
           WHEN COUNT(bu.unit_id) = 0 THEN 'NEVER_DONATED'
           WHEN MAX(bu.collection_date) < CURRENT_DATE - INTERVAL '6 months'
                THEN 'INACTIVE'
           WHEN COUNT(bu.unit_id) >= 5 THEN 'HIGHLY_ACTIVE'
           ELSE 'ACTIVE'
       END AS activity_status
FROM   donors d
LEFT JOIN blood_units bu ON bu.donor_id = d.donor_id
GROUP BY d.donor_id, d.first_name, d.last_name, d.blood_group, d.rh_factor,
         d.phone, d.email, d.is_active, d.registered_at
ORDER BY total_donations DESC;

COMMENT ON VIEW vw_donor_statistics IS
    'Donor directory with donation counts, last donation date, '
    'and computed activity status.';


-- ============================================================================
-- VIEW 5: vw_blood_group_summary
-- Distribution of registered donors by blood type.
-- ============================================================================
CREATE OR REPLACE VIEW vw_blood_group_summary AS
SELECT d.blood_group,
       d.rh_factor,
       COUNT(*)                                                     AS donor_count,
       ROUND(COUNT(*) * 100.0 / NULLIF(SUM(COUNT(*)) OVER (), 0), 1) AS percentage,
       (SELECT COUNT(*)
        FROM   blood_units bu2
        INNER JOIN donors d2 ON d2.donor_id = bu2.donor_id
        WHERE  d2.blood_group = d.blood_group
          AND  d2.rh_factor   = d.rh_factor
          AND  bu2.status     = 'AVAILABLE'
          AND  bu2.expiration_date >= CURRENT_DATE
       ) AS current_available_units
FROM   donors d
WHERE  d.is_active = TRUE
GROUP BY d.blood_group, d.rh_factor
ORDER BY donor_count DESC;

COMMENT ON VIEW vw_blood_group_summary IS
    'Blood group distribution among active donors with current available '
    'unit counts.';


-- ============================================================================
-- VIEW 6: vw_request_summary
-- All blood requests with hospital info and reservation progress.
-- ============================================================================
CREATE OR REPLACE VIEW vw_request_summary AS
SELECT br.request_id,
       h.name                              AS hospital_name,
       h.priority_level,
       br.requested_blood_group,
       br.requested_rh_factor,
       br.quantity                         AS requested_qty,
       br.urgency,
       br.fulfillment_status,
       br.requested_at,
       br.fulfilled_at,
       COALESCE(res.reserved_count, 0)     AS reserved_count,
       br.quantity - COALESCE(res.reserved_count, 0) AS remaining_needed,
       CASE br.urgency
           WHEN 'EMERGENCY' THEN 1
           WHEN 'URGENT'    THEN 2
           WHEN 'ROUTINE'   THEN 3
       END AS urgency_rank
FROM   blood_requests br
INNER JOIN hospitals h ON h.hospital_id = br.hospital_id
LEFT JOIN (
    SELECT request_id, COUNT(*) AS reserved_count
    FROM   unit_reservations
    GROUP BY request_id
) res ON res.request_id = br.request_id
ORDER BY urgency_rank, br.requested_at;

COMMENT ON VIEW vw_request_summary IS
    'Comprehensive request overview: hospital info, blood type, quantity, '
    'fulfillment status, reserved count, and urgency ranking.';


-- ============================================================================
-- VIEW 7: vw_reservation_summary
-- Detailed reservation audit trail joining all five tables.
-- ============================================================================
CREATE OR REPLACE VIEW vw_reservation_summary AS
SELECT ur.reservation_id,
       ur.reserved_at,
       bu.unit_id,
       bu.status                           AS unit_status,
       bu.collection_date,
       bu.expiration_date,
       d.donor_id,
       d.first_name || ' ' || d.last_name  AS donor_name,
       d.blood_group,
       d.rh_factor,
       br.request_id,
       br.urgency,
       br.fulfillment_status,
       h.name                              AS hospital_name,
       h.priority_level
FROM   unit_reservations ur
INNER JOIN blood_units bu     ON bu.unit_id    = ur.unit_id
INNER JOIN donors d           ON d.donor_id    = bu.donor_id
INNER JOIN blood_requests br  ON br.request_id = ur.request_id
INNER JOIN hospitals h        ON h.hospital_id = br.hospital_id
ORDER BY ur.reserved_at DESC;

COMMENT ON VIEW vw_reservation_summary IS
    'Full reservation audit trail: unit → donor → request → hospital. '
    'Useful for traceability and compliance reporting.';


-- ============================================================================
-- VIEW 8: vw_expiry_dashboard
-- Blood units approaching expiry, grouped by urgency tier.
-- ============================================================================
CREATE OR REPLACE VIEW vw_expiry_dashboard AS
SELECT bu.unit_id,
       d.blood_group,
       d.rh_factor,
       bu.collection_date,
       bu.expiration_date,
       bu.expiration_date - CURRENT_DATE AS days_remaining,
       bu.status,
       CASE
           WHEN bu.status = 'EXPIRED' THEN 'EXPIRED'
           WHEN bu.expiration_date - CURRENT_DATE <= 0 THEN 'PAST_DUE'
           WHEN bu.expiration_date - CURRENT_DATE <= 3 THEN 'CRITICAL'
           WHEN bu.expiration_date - CURRENT_DATE <= 7 THEN 'WARNING'
           WHEN bu.expiration_date - CURRENT_DATE <= 14 THEN 'MONITOR'
           ELSE 'SAFE'
       END AS expiry_tier
FROM   blood_units bu
INNER JOIN donors d ON d.donor_id = bu.donor_id
WHERE  bu.status IN ('AVAILABLE', 'EXPIRED')
ORDER BY days_remaining ASC;

COMMENT ON VIEW vw_expiry_dashboard IS
    'Expiry monitoring dashboard: all AVAILABLE and EXPIRED units with '
    'days remaining and urgency tier classification.';


-- ============================================================================
-- VIEW 9: vw_hospital_demand
-- Aggregated demand per hospital per blood type (pending + partial only).
-- ============================================================================
CREATE OR REPLACE VIEW vw_hospital_demand AS
SELECT h.hospital_id,
       h.name                     AS hospital_name,
       h.priority_level,
       br.requested_blood_group,
       br.requested_rh_factor,
       SUM(br.quantity)            AS total_demanded,
       COUNT(br.request_id)        AS request_count,
       SUM(br.quantity) - COALESCE(SUM(res.cnt), 0) AS outstanding_units
FROM   blood_requests br
INNER JOIN hospitals h ON h.hospital_id = br.hospital_id
LEFT JOIN (
    SELECT request_id, COUNT(*) AS cnt
    FROM   unit_reservations
    GROUP BY request_id
) res ON res.request_id = br.request_id
WHERE  br.fulfillment_status IN ('PENDING', 'PARTIAL')
GROUP BY h.hospital_id, h.name, h.priority_level,
         br.requested_blood_group, br.requested_rh_factor
ORDER BY h.priority_level DESC, total_demanded DESC;

COMMENT ON VIEW vw_hospital_demand IS
    'Outstanding demand per hospital per blood type. Only includes '
    'PENDING and PARTIAL requests.';


-- ============================================================================
-- VIEW 10: vw_blood_utilization
-- Blood utilization and wastage rates by blood type.
-- ============================================================================
CREATE OR REPLACE VIEW vw_blood_utilization AS
SELECT d.blood_group,
       d.rh_factor,
       COUNT(*)                                          AS total_units,
       COUNT(*) FILTER (WHERE bu.status = 'USED')        AS used,
       COUNT(*) FILTER (WHERE bu.status = 'EXPIRED')     AS expired,
       COUNT(*) FILTER (WHERE bu.status = 'AVAILABLE')   AS available,
       COUNT(*) FILTER (WHERE bu.status = 'RESERVED')    AS reserved,
       ROUND(COUNT(*) FILTER (WHERE bu.status = 'USED') * 100.0
             / NULLIF(COUNT(*), 0), 1)                   AS utilization_pct,
       ROUND(COUNT(*) FILTER (WHERE bu.status = 'EXPIRED') * 100.0
             / NULLIF(COUNT(*), 0), 1)                   AS wastage_pct
FROM   blood_units bu
INNER JOIN donors d ON d.donor_id = bu.donor_id
GROUP BY d.blood_group, d.rh_factor
ORDER BY utilization_pct DESC;

COMMENT ON VIEW vw_blood_utilization IS
    'Blood utilization and wastage rates per blood type. '
    'Helps identify supply chain inefficiencies.';


-- ============================================================================
-- MATERIALIZED VIEW 1: mv_inventory_dashboard
-- Snapshot of complete inventory state for fast dashboard rendering.
-- Must be refreshed periodically: REFRESH MATERIALIZED VIEW mv_inventory_dashboard;
-- ============================================================================
CREATE MATERIALIZED VIEW mv_inventory_dashboard AS
SELECT d.blood_group,
       d.rh_factor,
       bu.status,
       COUNT(*)                                             AS unit_count,
       SUM(bu.volume_ml)                                    AS total_volume_ml,
       MIN(bu.expiration_date)                              AS earliest_expiry,
       MAX(bu.expiration_date)                              AS latest_expiry,
       CURRENT_TIMESTAMP                                    AS snapshot_at
FROM   blood_units bu
INNER JOIN donors d ON d.donor_id = bu.donor_id
GROUP BY d.blood_group, d.rh_factor, bu.status
ORDER BY d.blood_group, d.rh_factor, bu.status;

COMMENT ON MATERIALIZED VIEW mv_inventory_dashboard IS
    'Materialised snapshot of inventory grouped by blood type and status. '
    'Refresh with: REFRESH MATERIALIZED VIEW mv_inventory_dashboard;';

-- Create index on the materialized view for fast lookups
CREATE INDEX idx_mv_inv_blood_type
    ON mv_inventory_dashboard (blood_group, rh_factor);


-- ============================================================================
-- MATERIALIZED VIEW 2: mv_monthly_report
-- Pre-computed monthly statistics for reporting.
-- ============================================================================
CREATE MATERIALIZED VIEW mv_monthly_report AS
WITH months AS (
    SELECT DISTINCT date_trunc('month', collection_date)::DATE AS month
    FROM blood_units
)
SELECT m.month,
       COALESCE(coll.collected, 0)  AS collected,
       COALESCE(coll.donors, 0)     AS unique_donors,
       COALESCE(used.used_count, 0) AS issued,
       COALESCE(exp.exp_count, 0)   AS expired,
       CURRENT_TIMESTAMP            AS snapshot_at
FROM   months m
LEFT JOIN (
    SELECT date_trunc('month', collection_date)::DATE AS month,
           COUNT(*)              AS collected,
           COUNT(DISTINCT donor_id) AS donors
    FROM   blood_units
    GROUP BY 1
) coll ON coll.month = m.month
LEFT JOIN (
    SELECT date_trunc('month', collection_date)::DATE AS month,
           COUNT(*) AS used_count
    FROM   blood_units WHERE status = 'USED'
    GROUP BY 1
) used ON used.month = m.month
LEFT JOIN (
    SELECT date_trunc('month', expiration_date)::DATE AS month,
           COUNT(*) AS exp_count
    FROM   blood_units WHERE status = 'EXPIRED'
    GROUP BY 1
) exp ON exp.month = m.month
ORDER BY m.month DESC;

COMMENT ON MATERIALIZED VIEW mv_monthly_report IS
    'Pre-computed monthly report: collections, unique donors, issued units, '
    'and expired units. Refresh with: REFRESH MATERIALIZED VIEW mv_monthly_report;';

CREATE INDEX idx_mv_monthly_month
    ON mv_monthly_report (month);


-- ============================================================================
-- END OF VIEWS
-- ============================================================================
