
SELECT d.blood_group,
       d.rh_factor,
       COUNT(*)                    AS available_units,
       SUM(bu.volume_ml)           AS total_volume_ml,
       MIN(bu.expiration_date)     AS earliest_expiry,
       MAX(bu.expiration_date)     AS latest_expiry
FROM   blood_units bu
INNER JOIN donors d ON d.donor_id = bu.donor_id
WHERE  bu.status           = 'AVAILABLE'
  AND  bu.expiration_date >= CURRENT_DATE
GROUP BY d.blood_group, d.rh_factor
ORDER BY d.blood_group, d.rh_factor;


SELECT bu.unit_id,
       d.blood_group,
       d.rh_factor,
       bu.expiration_date,
       bu.expiration_date - CURRENT_DATE AS days_remaining,
       CASE
           WHEN bu.expiration_date - CURRENT_DATE <= 2 THEN 'CRITICAL'
           WHEN bu.expiration_date - CURRENT_DATE <= 5 THEN 'WARNING'
           ELSE 'MONITOR'
       END AS expiry_alert
FROM   blood_units bu
INNER JOIN donors d ON d.donor_id = bu.donor_id
WHERE  bu.status = 'AVAILABLE'
  AND  bu.expiration_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
ORDER BY bu.expiration_date ASC;


SELECT bu.unit_id,
       COALESCE(d.first_name || ' ' || d.last_name, 'Unknown Donor') AS donor_name,
       d.blood_group,
       d.rh_factor,
       bu.collection_date,
       bu.expiration_date,
       CURRENT_DATE - bu.expiration_date AS days_since_expiry,
       bu.volume_ml
FROM   blood_units bu
LEFT JOIN donors d ON d.donor_id = bu.donor_id
WHERE  bu.status = 'EXPIRED'
ORDER BY bu.expiration_date DESC;



SELECT date_trunc('month', bu.collection_date)::DATE AS month,
       COUNT(*)                                       AS units_collected,
       COUNT(DISTINCT bu.donor_id)                    AS unique_donors,
       SUM(bu.volume_ml)                              AS total_volume_ml
FROM   blood_units bu
GROUP BY date_trunc('month', bu.collection_date)
ORDER BY month DESC;



SELECT d.donor_id,
       d.first_name || ' ' || d.last_name AS donor_name,
       d.blood_group,
       d.rh_factor,
       COUNT(bu.unit_id)                   AS total_donations,
       RANK() OVER (ORDER BY COUNT(bu.unit_id) DESC) AS donor_rank
FROM   donors d
INNER JOIN blood_units bu ON bu.donor_id = d.donor_id
GROUP BY d.donor_id, d.first_name, d.last_name, d.blood_group, d.rh_factor
ORDER BY total_donations DESC
LIMIT 10;


SELECT d.donor_id,
       d.first_name || ' ' || d.last_name AS donor_name,
       bu.unit_id,
       bu.collection_date,
       LAG(bu.collection_date) OVER (
           PARTITION BY d.donor_id ORDER BY bu.collection_date
       ) AS prev_donation_date,
       bu.collection_date - LAG(bu.collection_date) OVER (
           PARTITION BY d.donor_id ORDER BY bu.collection_date
       ) AS days_between_donations
FROM   donors d
INNER JOIN blood_units bu ON bu.donor_id = d.donor_id
ORDER BY d.donor_id, bu.collection_date;



SELECT h.hospital_id,
       h.name AS hospital_name,
       h.priority_level,
       COUNT(br.request_id)                                    AS total_requests,
       SUM(br.quantity)                                        AS total_units_requested,
       AVG(br.quantity)::NUMERIC(5,1)                          AS avg_quantity_per_request,
       COUNT(*) FILTER (WHERE br.fulfillment_status = 'FULFILLED')  AS fulfilled_count,
       COUNT(*) FILTER (WHERE br.fulfillment_status = 'PARTIAL')    AS partial_count,
       COUNT(*) FILTER (WHERE br.fulfillment_status = 'PENDING')    AS pending_count,
       COUNT(*) FILTER (WHERE br.fulfillment_status = 'CANCELLED')  AS cancelled_count
FROM   hospitals h
LEFT JOIN blood_requests br ON br.hospital_id = h.hospital_id
GROUP BY h.hospital_id, h.name, h.priority_level
ORDER BY total_requests DESC;


SELECT br.requested_blood_group,
       br.requested_rh_factor,
       COUNT(*)       AS request_count,
       SUM(br.quantity) AS total_units_demanded
FROM   blood_requests br
GROUP BY br.requested_blood_group, br.requested_rh_factor
HAVING COUNT(*) = (
    SELECT MAX(cnt) FROM (
        SELECT COUNT(*) AS cnt
        FROM blood_requests
        GROUP BY requested_blood_group, requested_rh_factor
    ) sub
)
ORDER BY total_units_demanded DESC;



WITH request_stats AS (
    SELECT hospital_id,
           COUNT(*)                                                       AS total,
           COUNT(*) FILTER (WHERE fulfillment_status = 'FULFILLED')       AS fulfilled,
           COUNT(*) FILTER (WHERE fulfillment_status IN ('FULFILLED','PARTIAL')) AS at_least_partial
    FROM blood_requests
    GROUP BY hospital_id
)
SELECT h.name                                                          AS hospital_name,
       h.priority_level,
       rs.total                                                        AS total_requests,
       rs.fulfilled                                                    AS fully_fulfilled,
       rs.at_least_partial                                             AS at_least_partial,
       ROUND(rs.fulfilled * 100.0 / NULLIF(rs.total, 0), 1)           AS fulfillment_pct,
       ROUND(rs.at_least_partial * 100.0 / NULLIF(rs.total, 0), 1)    AS partial_plus_pct
FROM   request_stats rs
INNER JOIN hospitals h ON h.hospital_id = rs.hospital_id
ORDER BY fulfillment_pct DESC;


SELECT br.request_id,
       h.name                                        AS hospital_name,
       h.priority_level,
       br.requested_blood_group,
       br.requested_rh_factor,
       br.quantity,
       br.urgency,
       br.requested_at,
       CASE br.urgency
           WHEN 'EMERGENCY' THEN 1
           WHEN 'URGENT'    THEN 2
           WHEN 'ROUTINE'   THEN 3
       END AS priority_score
FROM   blood_requests br
INNER JOIN hospitals h ON h.hospital_id = br.hospital_id
WHERE  br.fulfillment_status = 'PENDING'
ORDER BY priority_score ASC, br.requested_at ASC;



SELECT br.request_id,
       h.name                    AS hospital_name,
       br.requested_blood_group,
       br.requested_rh_factor,
       br.quantity,
       br.fulfillment_status,
       br.requested_at,
       br.fulfilled_at,
       COALESCE(
           EXTRACT(EPOCH FROM (br.fulfilled_at - br.requested_at)) / 60,
           NULL
       )::INT AS response_time_minutes
FROM   blood_requests br
INNER JOIN hospitals h ON h.hospital_id = br.hospital_id
WHERE  br.urgency = 'EMERGENCY'
ORDER BY br.requested_at DESC;



SELECT d.blood_group,
       d.rh_factor,
       COUNT(*)                                                     AS available_units,
       AVG(CURRENT_DATE - bu.collection_date)::NUMERIC(5,1)        AS avg_age_days,
       MIN(CURRENT_DATE - bu.collection_date)                      AS youngest_unit_days,
       MAX(CURRENT_DATE - bu.collection_date)                      AS oldest_unit_days
FROM   blood_units bu
INNER JOIN donors d ON d.donor_id = bu.donor_id
WHERE  bu.status = 'AVAILABLE'
  AND  bu.expiration_date >= CURRENT_DATE
GROUP BY d.blood_group, d.rh_factor
ORDER BY avg_age_days DESC;


SELECT ur.reservation_id,
       ur.reserved_at,
       bu.unit_id,
       d.first_name || ' ' || d.last_name AS donor_name,
       d.blood_group,
       d.rh_factor,
       bu.status                          AS unit_status,
       br.request_id,
       h.name                             AS hospital_name,
       br.urgency,
       br.fulfillment_status
FROM   unit_reservations ur
INNER JOIN blood_units bu    ON bu.unit_id     = ur.unit_id
INNER JOIN donors d          ON d.donor_id     = bu.donor_id
INNER JOIN blood_requests br ON br.request_id  = ur.request_id
INNER JOIN hospitals h       ON h.hospital_id  = br.hospital_id
ORDER BY ur.reserved_at DESC;



SELECT date_trunc('month', ur.reserved_at)::DATE AS month,
       COUNT(*)                                   AS units_issued
FROM   blood_units bu
INNER JOIN unit_reservations ur ON ur.unit_id = bu.unit_id
WHERE  bu.status = 'USED'
GROUP BY date_trunc('month', ur.reserved_at)
ORDER BY month DESC;



SELECT d.blood_group,
       d.rh_factor,
       COUNT(*)                                              AS total_units,
       COUNT(*) FILTER (WHERE bu.status = 'USED')            AS used_units,
       COUNT(*) FILTER (WHERE bu.status = 'EXPIRED')         AS expired_units,
       COUNT(*) FILTER (WHERE bu.status = 'AVAILABLE')       AS available_units,
       COUNT(*) FILTER (WHERE bu.status = 'RESERVED')        AS reserved_units,
       ROUND(
           COUNT(*) FILTER (WHERE bu.status = 'USED') * 100.0 /
           NULLIF(COUNT(*), 0), 1
       ) AS utilization_pct,
       ROUND(
           COUNT(*) FILTER (WHERE bu.status = 'EXPIRED') * 100.0 /
           NULLIF(COUNT(*), 0), 1
       ) AS wastage_pct
FROM   blood_units bu
INNER JOIN donors d ON d.donor_id = bu.donor_id
GROUP BY d.blood_group, d.rh_factor
ORDER BY utilization_pct DESC;



SELECT d.blood_group,
       d.rh_factor,
       COUNT(*)                AS expired_count,
       SUM(bu.volume_ml)       AS wasted_volume_ml,
       MIN(bu.collection_date) AS earliest_collection,
       MAX(bu.expiration_date) AS latest_expiration,
       AVG(bu.expiration_date - bu.collection_date)::INT AS avg_shelf_life_days
FROM   blood_units bu
INNER JOIN donors d ON d.donor_id = bu.donor_id
WHERE  bu.status = 'EXPIRED'
GROUP BY d.blood_group, d.rh_factor
ORDER BY expired_count DESC;



SELECT d.blood_group,
       d.rh_factor,
       COUNT(*)                                                  AS donor_count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1)       AS percentage
FROM   donors d
WHERE  d.is_active = TRUE
GROUP BY d.blood_group, d.rh_factor
ORDER BY donor_count DESC;


SELECT d.donor_id,
       d.first_name || ' ' || d.last_name AS donor_name,
       d.blood_group,
       d.rh_factor,
       d.is_active,
       COUNT(bu.unit_id)                   AS total_donations,
       MAX(bu.collection_date)             AS last_donation_date,
       CASE
           WHEN COUNT(bu.unit_id) = 0                 THEN 'NEVER_DONATED'
           WHEN MAX(bu.collection_date) < CURRENT_DATE - INTERVAL '6 months' THEN 'INACTIVE'
           WHEN COUNT(bu.unit_id) >= 5                THEN 'HIGHLY_ACTIVE'
           ELSE 'ACTIVE'
       END AS activity_status
FROM   donors d
LEFT JOIN blood_units bu ON bu.donor_id = d.donor_id
GROUP BY d.donor_id, d.first_name, d.last_name, d.blood_group, d.rh_factor, d.is_active
ORDER BY total_donations DESC;


WITH demand AS (
    SELECT requested_blood_group AS blood_group,
           requested_rh_factor   AS rh_factor,
           SUM(quantity)          AS total_demanded
    FROM   blood_requests
    WHERE  fulfillment_status IN ('PENDING', 'PARTIAL')
    GROUP BY requested_blood_group, requested_rh_factor
),
supply AS (
    SELECT d.blood_group,
           d.rh_factor,
           COUNT(*) AS total_available
    FROM   blood_units bu
    INNER JOIN donors d ON d.donor_id = bu.donor_id
    WHERE  bu.status = 'AVAILABLE'
      AND  bu.expiration_date >= CURRENT_DATE
    GROUP BY d.blood_group, d.rh_factor
)
SELECT COALESCE(dem.blood_group, sup.blood_group) AS blood_group,
       COALESCE(dem.rh_factor,   sup.rh_factor)   AS rh_factor,
       COALESCE(sup.total_available, 0)            AS available,
       COALESCE(dem.total_demanded, 0)             AS pending_demand,
       COALESCE(sup.total_available, 0) - COALESCE(dem.total_demanded, 0) AS surplus_deficit
FROM   demand dem
FULL OUTER JOIN supply sup
  ON  sup.blood_group = dem.blood_group
  AND sup.rh_factor   = dem.rh_factor
ORDER BY surplus_deficit ASC;


WITH monthly AS (
    SELECT date_trunc('month', bu.collection_date)::DATE AS month,
           COUNT(*)                                       AS collected,
           COUNT(*) FILTER (WHERE bu.status = 'USED')     AS used,
           COUNT(*) FILTER (WHERE bu.status = 'EXPIRED')  AS expired
    FROM   blood_units bu
    GROUP BY date_trunc('month', bu.collection_date)
)
SELECT month,
       collected,
       used,
       expired,
       ROUND(used * 100.0 / NULLIF(collected, 0), 1) AS turnover_pct,
       SUM(collected) OVER (ORDER BY month)           AS cumulative_collected,
       SUM(used)      OVER (ORDER BY month)           AS cumulative_used
FROM   monthly
ORDER BY month DESC;



SELECT d.donor_id,
       d.first_name || ' ' || d.last_name AS donor_name,
       d.blood_group,
       d.rh_factor,
       COUNT(bu.unit_id)                   AS donation_count,
       DENSE_RANK() OVER (ORDER BY COUNT(bu.unit_id) DESC) AS dense_rank,
       ROW_NUMBER() OVER (ORDER BY COUNT(bu.unit_id) DESC, d.donor_id) AS row_num
FROM   donors d
INNER JOIN blood_units bu ON bu.donor_id = d.donor_id
WHERE  d.is_active = TRUE
GROUP BY d.donor_id, d.first_name, d.last_name, d.blood_group, d.rh_factor
ORDER BY dense_rank;


SELECT h.hospital_id,
       h.name,
       h.priority_level,
       COUNT(br.request_id) AS request_count,
       SUM(br.quantity)      AS total_units
FROM   hospitals h
INNER JOIN blood_requests br ON br.hospital_id = h.hospital_id
GROUP BY h.hospital_id, h.name, h.priority_level
HAVING SUM(br.quantity) > (
    SELECT AVG(total_qty)
    FROM (
        SELECT SUM(quantity) AS total_qty
        FROM blood_requests
        GROUP BY hospital_id
    ) sub
)
ORDER BY total_units DESC;


SELECT h.hospital_id,
       h.name                                                      AS hospital_name,
       h.priority_level,
       SUM(br.quantity)                                            AS total_demand,
       RANK() OVER (ORDER BY SUM(br.quantity) DESC)                AS demand_rank,
       SUM(br.quantity) * 100.0 / SUM(SUM(br.quantity)) OVER ()   AS demand_share_pct
FROM   hospitals h
INNER JOIN blood_requests br ON br.hospital_id = h.hospital_id
GROUP BY h.hospital_id, h.name, h.priority_level
ORDER BY demand_rank;


WITH emergency AS (
    SELECT br.request_id,
           h.name AS hospital_name,
           br.requested_blood_group,
           br.requested_rh_factor,
           br.quantity,
           br.fulfillment_status,
           br.requested_at,
           br.fulfilled_at,
           EXTRACT(EPOCH FROM (br.fulfilled_at - br.requested_at)) / 60.0 AS response_minutes
    FROM   blood_requests br
    INNER JOIN hospitals h ON h.hospital_id = br.hospital_id
    WHERE  br.urgency = 'EMERGENCY'
)
SELECT request_id,
       hospital_name,
       requested_blood_group,
       requested_rh_factor,
       quantity,
       fulfillment_status,
       ROUND(response_minutes::NUMERIC, 1) AS response_min,
       AVG(response_minutes) OVER ()::NUMERIC(8,1) AS avg_response_min,
       RANK() OVER (ORDER BY response_minutes ASC NULLS LAST) AS speed_rank
FROM   emergency
ORDER BY speed_rank;



SELECT bu.collection_date,
       COUNT(*)                        AS units_collected,
       COUNT(DISTINCT bu.donor_id)     AS unique_donors,
       SUM(bu.volume_ml)               AS total_volume_ml,
       STRING_AGG(DISTINCT d.blood_group::TEXT || d.rh_factor::TEXT, ', '
                  ORDER BY d.blood_group::TEXT || d.rh_factor::TEXT) AS blood_types
FROM   blood_units bu
INNER JOIN donors d ON d.donor_id = bu.donor_id
WHERE  bu.collection_date BETWEEN '2026-06-01' AND '2026-06-30'
GROUP BY bu.collection_date
ORDER BY bu.collection_date;



SELECT EXTRACT(ISOYEAR FROM bu.collection_date)::INT AS year,
       EXTRACT(WEEK    FROM bu.collection_date)::INT AS week_number,
       COUNT(*)                                       AS units_this_week,
       SUM(COUNT(*)) OVER (
           ORDER BY EXTRACT(ISOYEAR FROM bu.collection_date),
                    EXTRACT(WEEK    FROM bu.collection_date)
       ) AS cumulative_units
FROM   blood_units bu
GROUP BY EXTRACT(ISOYEAR FROM bu.collection_date),
         EXTRACT(WEEK    FROM bu.collection_date)
ORDER BY year, week_number;


WITH months AS (
    SELECT DISTINCT date_trunc('month', collection_date)::DATE AS month FROM blood_units
    UNION
    SELECT DISTINCT date_trunc('month', reserved_at)::DATE FROM unit_reservations
)
SELECT m.month,
       COALESCE(coll.collected, 0)   AS collected,
       COALESCE(res.reserved, 0)     AS reserved,
       COALESCE(iss.issued, 0)       AS issued,
       COALESCE(exp.expired, 0)      AS expired
FROM   months m
LEFT JOIN (
    SELECT date_trunc('month', collection_date)::DATE AS month, COUNT(*) AS collected
    FROM blood_units GROUP BY 1
) coll ON coll.month = m.month
LEFT JOIN (
    SELECT date_trunc('month', reserved_at)::DATE AS month, COUNT(*) AS reserved
    FROM unit_reservations GROUP BY 1
) res ON res.month = m.month
LEFT JOIN (
    SELECT date_trunc('month', reserved_at)::DATE AS month, COUNT(*) AS issued
    FROM unit_reservations ur INNER JOIN blood_units bu ON bu.unit_id = ur.unit_id
    WHERE bu.status = 'USED' GROUP BY 1
) iss ON iss.month = m.month
LEFT JOIN (
    SELECT date_trunc('month', expiration_date)::DATE AS month, COUNT(*) AS expired
    FROM blood_units WHERE status = 'EXPIRED' GROUP BY 1
) exp ON exp.month = m.month
ORDER BY m.month DESC;

SELECT EXTRACT(YEAR FROM bu.collection_date)::INT AS year,
       COUNT(*)                                    AS total_collections,
       COUNT(DISTINCT bu.donor_id)                 AS unique_donors,
       COUNT(*) FILTER (WHERE bu.status = 'USED')     AS units_used,
       COUNT(*) FILTER (WHERE bu.status = 'EXPIRED')   AS units_expired,
       COUNT(*) FILTER (WHERE bu.status = 'AVAILABLE') AS units_available,
       COUNT(*) FILTER (WHERE bu.status = 'RESERVED')  AS units_reserved,
       SUM(bu.volume_ml)                                AS total_volume_ml
FROM   blood_units bu
GROUP BY EXTRACT(YEAR FROM bu.collection_date)
ORDER BY year DESC;



WITH all_types AS (
    SELECT bg.bg, rh.rh
    FROM   (VALUES ('A'),('B'),('AB'),('O'))          AS bg(bg),
           (VALUES ('POSITIVE'),('NEGATIVE'))         AS rh(rh)
),
inventory AS (
    SELECT d.blood_group::TEXT AS bg,
           d.rh_factor::TEXT   AS rh,
           COUNT(*)             AS available
    FROM   blood_units bu
    INNER JOIN donors d ON d.donor_id = bu.donor_id
    WHERE  bu.status = 'AVAILABLE' AND bu.expiration_date >= CURRENT_DATE
    GROUP BY d.blood_group, d.rh_factor
)
SELECT t.bg                            AS blood_group,
       t.rh                            AS rh_factor,
       COALESCE(i.available, 0)        AS available_units,
       CASE WHEN COALESCE(i.available, 0) = 0 THEN 'OUT OF STOCK'
            WHEN COALESCE(i.available, 0) < 3    THEN 'LOW STOCK'
            ELSE 'ADEQUATE'
       END AS stock_status
FROM   all_types t
LEFT JOIN inventory i ON i.bg = t.bg AND i.rh = t.rh
ORDER BY t.bg, t.rh;


WITH RECURSIVE compatibility(donor_type, recipient_type, depth) AS (
    -- Base: direct compatibilities (simplified ABO+Rh rules)
    VALUES
        ('O NEGATIVE',  'O NEGATIVE',  0),
        ('O NEGATIVE',  'O POSITIVE',  0),
        ('O NEGATIVE',  'A NEGATIVE',  0),
        ('O NEGATIVE',  'A POSITIVE',  0),
        ('O NEGATIVE',  'B NEGATIVE',  0),
        ('O NEGATIVE',  'B POSITIVE',  0),
        ('O NEGATIVE',  'AB NEGATIVE', 0),
        ('O NEGATIVE',  'AB POSITIVE', 0),
        ('O POSITIVE',  'O POSITIVE',  0),
        ('O POSITIVE',  'A POSITIVE',  0),
        ('O POSITIVE',  'B POSITIVE',  0),
        ('O POSITIVE',  'AB POSITIVE', 0),
        ('A NEGATIVE',  'A NEGATIVE',  0),
        ('A NEGATIVE',  'A POSITIVE',  0),
        ('A NEGATIVE',  'AB NEGATIVE', 0),
        ('A NEGATIVE',  'AB POSITIVE', 0),
        ('A POSITIVE',  'A POSITIVE',  0),
        ('A POSITIVE',  'AB POSITIVE', 0),
        ('B NEGATIVE',  'B NEGATIVE',  0),
        ('B NEGATIVE',  'B POSITIVE',  0),
        ('B NEGATIVE',  'AB NEGATIVE', 0),
        ('B NEGATIVE',  'AB POSITIVE', 0),
        ('B POSITIVE',  'B POSITIVE',  0),
        ('B POSITIVE',  'AB POSITIVE', 0),
        ('AB NEGATIVE', 'AB NEGATIVE', 0),
        ('AB NEGATIVE', 'AB POSITIVE', 0),
        ('AB POSITIVE', 'AB POSITIVE', 0)
)
SELECT donor_type,
       recipient_type,
       'Direct' AS compatibility_level
FROM   compatibility
ORDER BY donor_type, recipient_type;



SELECT h.hospital_id,
       h.name,
       h.priority_level,
       h.is_active,
       COALESCE(COUNT(br.request_id), 0) AS total_requests
FROM   blood_requests br
RIGHT JOIN hospitals h ON h.hospital_id = br.hospital_id
GROUP BY h.hospital_id, h.name, h.priority_level, h.is_active
ORDER BY total_requests ASC;



SELECT (SELECT COUNT(*) FROM donors WHERE is_active = TRUE)              AS active_donors,
       (SELECT COUNT(*) FROM blood_units WHERE status = 'AVAILABLE'
                          AND expiration_date >= CURRENT_DATE)           AS available_units,
       (SELECT COUNT(*) FROM blood_units WHERE status = 'RESERVED')      AS reserved_units,
       (SELECT COUNT(*) FROM blood_units WHERE status = 'USED')          AS issued_units,
       (SELECT COUNT(*) FROM blood_units WHERE status = 'EXPIRED')       AS expired_units,
       (SELECT COUNT(*) FROM hospitals WHERE is_active = TRUE)           AS active_hospitals,
       (SELECT COUNT(*) FROM blood_requests
               WHERE fulfillment_status = 'PENDING')                     AS pending_requests,
       (SELECT COUNT(*) FROM blood_requests
               WHERE urgency = 'EMERGENCY'
                 AND fulfillment_status = 'PENDING')                     AS emergency_pending,
       (SELECT COUNT(*) FROM blood_units
               WHERE status = 'AVAILABLE'
                 AND expiration_date BETWEEN CURRENT_DATE
                     AND CURRENT_DATE + INTERVAL '3 days')               AS expiring_soon;


-- ============================================================================
-- END OF QUERIES
-- ============================================================================
