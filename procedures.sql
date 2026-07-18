-- ============================================================================
-- Blood Bank & Emergency Donor-Matching System
-- Stored Procedures & Functions — PostgreSQL
-- ============================================================================
-- DEPENDENCY: Requires schema.sql and triggers.sql to be executed first.
--
-- CONVENTIONS:
--   fn_*  → FUNCTION  (returns a value, runs inside caller's transaction)
--   sp_*  → PROCEDURE (manages its own transaction with COMMIT / ROLLBACK)
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 0. CLEAN SLATE — drop existing objects
-- ────────────────────────────────────────────────────────────────────────────

DROP FUNCTION  IF EXISTS fn_register_donor       CASCADE;
DROP FUNCTION  IF EXISTS fn_add_blood_unit        CASCADE;
DROP FUNCTION  IF EXISTS fn_get_available_inventory CASCADE;
DROP PROCEDURE IF EXISTS sp_reserve_blood_units   CASCADE;
DROP PROCEDURE IF EXISTS sp_cancel_reservation    CASCADE;
DROP PROCEDURE IF EXISTS sp_issue_blood           CASCADE;
DROP PROCEDURE IF EXISTS sp_daily_expiry_maintenance CASCADE;

-- ============================================================================
-- 1. FUNCTION: fn_register_donor
-- ============================================================================
-- Registers a new blood donor.
-- Returns the new donor_id on success.
-- Raises an exception on duplicate phone/email.
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_register_donor(
    p_first_name    VARCHAR,
    p_last_name     VARCHAR,
    p_date_of_birth DATE,
    p_blood_group   blood_group_enum,
    p_rh_factor     rh_factor_enum,
    p_phone         VARCHAR,
    p_email         VARCHAR  DEFAULT NULL,
    p_address       TEXT     DEFAULT NULL
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_donor_id INT;
BEGIN
    -- ── Pre-validation (gives a clearer error than the CHECK constraint) ──
    IF p_date_of_birth > CURRENT_DATE - INTERVAL '18 years' THEN
        RAISE EXCEPTION 'UNDERAGE_DONOR: Donor must be at least 18 years old. '
                         'Provided date_of_birth: %', p_date_of_birth;
    END IF;

    INSERT INTO donors (
        first_name, last_name, date_of_birth,
        blood_group, rh_factor,
        phone, email, address
    )
    VALUES (
        p_first_name, p_last_name, p_date_of_birth,
        p_blood_group, p_rh_factor,
        p_phone, p_email, p_address
    )
    RETURNING donor_id INTO v_donor_id;

    RAISE NOTICE 'REGISTERED: Donor "% %" (ID: %, Blood: % %)',
        p_first_name, p_last_name, v_donor_id, p_blood_group, p_rh_factor;

    RETURN v_donor_id;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'DUPLICATE_DONOR: A donor with phone "%" or email "%" '
                         'already exists.', p_phone, p_email;
    WHEN check_violation THEN
        RAISE EXCEPTION 'VALIDATION_ERROR: One or more values violate domain '
                         'constraints (age, phone format, etc.).';
END;
$$;

COMMENT ON FUNCTION fn_register_donor IS
    'Registers a new blood donor with demographics, blood type, and contact '
    'details. Returns the auto-generated donor_id. Validates age ≥ 18 and '
    'uniqueness of phone/email.';


-- ============================================================================
-- 2. FUNCTION: fn_add_blood_unit
-- ============================================================================
-- Records a new blood unit drawn from a registered donor.
-- Automatically calculates the expiration date (default +42 days).
-- Status is set to AVAILABLE (may be auto-expired by the trigger if past-due).
-- Returns the new unit_id.
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_add_blood_unit(
    p_donor_id        INT,
    p_collection_date DATE     DEFAULT CURRENT_DATE,
    p_volume_ml       NUMERIC  DEFAULT 450.00,
    p_shelf_life_days INT      DEFAULT 42
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_unit_id     INT;
    v_expiration  DATE;
    v_donor_active BOOLEAN;
BEGIN
    -- ── Validate donor exists and is active ──
    SELECT is_active INTO v_donor_active
    FROM   donors
    WHERE  donor_id = p_donor_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'INVALID_DONOR: Donor ID % does not exist.', p_donor_id;
    END IF;

    IF NOT v_donor_active THEN
        RAISE EXCEPTION 'INACTIVE_DONOR: Donor ID % is deactivated.', p_donor_id;
    END IF;

    -- ── Calculate expiration ──
    v_expiration := p_collection_date + p_shelf_life_days;

    INSERT INTO blood_units (
        donor_id, collection_date, expiration_date, volume_ml
    )
    VALUES (
        p_donor_id, p_collection_date, v_expiration, p_volume_ml
    )
    RETURNING unit_id INTO v_unit_id;

    RAISE NOTICE 'COLLECTED: Unit ID % from Donor ID % (collected: %, expires: %)',
        v_unit_id, p_donor_id, p_collection_date, v_expiration;

    RETURN v_unit_id;

EXCEPTION
    WHEN check_violation THEN
        RAISE EXCEPTION 'VALIDATION_ERROR: Volume must be positive and '
                         'expiration must be after collection date.';
END;
$$;

COMMENT ON FUNCTION fn_add_blood_unit IS
    'Records a new blood unit collection from a donor. Calculates expiration '
    'date as collection_date + shelf_life_days (default 42). Sets initial '
    'status to AVAILABLE. The trigger fn_auto_expire_blood_unit will auto-expire '
    'the unit if the expiration date has already passed.';


-- ============================================================================
-- 3. PROCEDURE: sp_reserve_blood_units   *** CRITICAL PATH ***
-- ============================================================================
-- Reserves available blood units to fulfill a blood request.
--
-- CONCURRENCY STRATEGY:
--   SELECT ... FOR UPDATE OF bu  — acquires row-level exclusive locks on
--   candidate blood_units rows.  In READ COMMITTED (PostgreSQL default),
--   a competing transaction that hits the same rows will:
--     1. WAIT for the lock to be released.
--     2. Re-evaluate the WHERE clause on the latest committed row version.
--     3. Skip the row if status is no longer 'AVAILABLE'.
--   This guarantees serialised access without application-level locking.
--
-- TRANSACTION CONTROL:
--   COMMIT on success.  ROLLBACK + RAISE EXCEPTION on failure.
--
-- MODES:
--   p_allow_partial = FALSE (default): all-or-nothing.
--     If fewer units are available than requested, ROLLBACK everything.
--   p_allow_partial = TRUE: partial fulfillment.
--     Reserve whatever is available, set status to PARTIAL.
-- ============================================================================

CREATE OR REPLACE PROCEDURE sp_reserve_blood_units(
    p_request_id    INT,
    p_allow_partial BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_bg               blood_group_enum;
    v_rh               rh_factor_enum;
    v_total_qty        INT;
    v_current_status   fulfillment_status_enum;
    v_already_reserved INT;
    v_needed           INT;
    v_unit             RECORD;
    v_reserved         INT := 0;
BEGIN
    -- ╔═══════════════════════════════════════════════════════════════════╗
    -- ║ STEP 1: Validate and lock the request row                       ║
    -- ╚═══════════════════════════════════════════════════════════════════╝
    SELECT requested_blood_group,
           requested_rh_factor,
           quantity,
           fulfillment_status
    INTO   v_bg, v_rh, v_total_qty, v_current_status
    FROM   blood_requests
    WHERE  request_id = p_request_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'REQUEST_NOT_FOUND: Blood request ID % does not exist.',
                         p_request_id;
    END IF;

    IF v_current_status NOT IN ('PENDING', 'PARTIAL') THEN
        RAISE EXCEPTION 'INVALID_REQUEST_STATUS: Request % has status "%" — '
                         'only PENDING or PARTIAL requests can be reserved.',
                         p_request_id, v_current_status;
    END IF;

    -- ── Account for units already reserved (when topping up a PARTIAL) ──
    SELECT COUNT(*) INTO v_already_reserved
    FROM   unit_reservations
    WHERE  request_id = p_request_id;

    v_needed := v_total_qty - v_already_reserved;

    IF v_needed <= 0 THEN
        RAISE EXCEPTION 'ALREADY_SATISFIED: Request % already has % of % '
                         'unit(s) reserved.',
                         p_request_id, v_already_reserved, v_total_qty;
    END IF;

    -- ╔═══════════════════════════════════════════════════════════════════╗
    -- ║ STEP 2: Lock and reserve available matching units (FIFO expiry) ║
    -- ║                                                                 ║
    -- ║  SELECT ... FOR UPDATE OF bu                                    ║
    -- ║  Acquires exclusive row locks on blood_units.                   ║
    -- ║  Concurrent transactions will BLOCK here until we COMMIT/ROLL.  ║
    -- ╚═══════════════════════════════════════════════════════════════════╝
    FOR v_unit IN
        SELECT bu.unit_id
        FROM   blood_units bu
        INNER JOIN donors d ON d.donor_id = bu.donor_id
        WHERE  d.blood_group     = v_bg
          AND  d.rh_factor       = v_rh
          AND  bu.status         = 'AVAILABLE'
          AND  bu.expiration_date >= CURRENT_DATE
        ORDER BY bu.expiration_date ASC
        FOR UPDATE OF bu
        LIMIT  v_needed
    LOOP
        -- Reserve this unit
        UPDATE blood_units
        SET    status = 'RESERVED'
        WHERE  unit_id = v_unit.unit_id;

        INSERT INTO unit_reservations (unit_id, request_id)
        VALUES (v_unit.unit_id, p_request_id);

        v_reserved := v_reserved + 1;
    END LOOP;

    -- ╔═══════════════════════════════════════════════════════════════════╗
    -- ║ STEP 3: Evaluate results and finalise transaction               ║
    -- ╚═══════════════════════════════════════════════════════════════════╝

    IF v_reserved = 0 THEN
        -- Nothing available at all — ROLLBACK and error
        ROLLBACK;
        RAISE EXCEPTION 'NO_UNITS_AVAILABLE: Zero available % % units found '
                         'in inventory. Transaction rolled back.',
                         v_bg, v_rh;

    ELSIF v_reserved < v_needed AND NOT p_allow_partial THEN
        -- Not enough — ALL-OR-NOTHING mode — ROLLBACK everything
        ROLLBACK;
        RAISE EXCEPTION 'INSUFFICIENT_UNITS: Needed % units of % %, only % '
                         'available. All-or-nothing mode — transaction rolled '
                         'back, no units were reserved.',
                         v_needed, v_bg, v_rh, v_reserved;

    ELSIF v_reserved < v_needed AND p_allow_partial THEN
        -- Partial fulfillment accepted
        UPDATE blood_requests
        SET    fulfillment_status = 'PARTIAL'
        WHERE  request_id = p_request_id;

        COMMIT;
        RAISE NOTICE 'PARTIAL_FILL: Reserved % of % needed units for request '
                     '%. Status → PARTIAL.',
                     v_reserved, v_needed, p_request_id;

    ELSE
        -- Full quantity met
        UPDATE blood_requests
        SET    fulfillment_status = 'FULFILLED',
               fulfilled_at      = NOW()
        WHERE  request_id = p_request_id;

        COMMIT;
        RAISE NOTICE 'FULFILLED: All % unit(s) reserved for request %. '
                     'Status → FULFILLED.',
                     v_needed, p_request_id;
    END IF;
END;
$$;

COMMENT ON PROCEDURE sp_reserve_blood_units IS
    'Reserves AVAILABLE blood units for a pending request. Uses SELECT ... '
    'FOR UPDATE to acquire row-level locks, preventing race-condition '
    'double-booking. Supports all-or-nothing (default) and partial modes. '
    'FIFO ordering by expiration_date ensures oldest units are used first. '
    'Blood type is resolved by JOINing blood_units to donors (3NF).';


-- ============================================================================
-- 4. PROCEDURE: sp_cancel_reservation
-- ============================================================================
-- Cancels a blood request and releases all its reserved (not USED) units
-- back to AVAILABLE status.
-- ============================================================================

CREATE OR REPLACE PROCEDURE sp_cancel_reservation(
    p_request_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status   fulfillment_status_enum;
    v_released INT;
    v_deleted  INT;
BEGIN
    -- ── Validate ──
    SELECT fulfillment_status INTO v_status
    FROM   blood_requests
    WHERE  request_id = p_request_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'REQUEST_NOT_FOUND: Blood request % does not exist.',
                         p_request_id;
    END IF;

    IF v_status = 'CANCELLED' THEN
        RAISE EXCEPTION 'ALREADY_CANCELLED: Request % is already cancelled.',
                         p_request_id;
    END IF;

    -- ── Release reserved units back to AVAILABLE ──
    -- (USED units remain USED — blood that has been issued cannot be un-issued)
    UPDATE blood_units
    SET    status = 'AVAILABLE'
    WHERE  unit_id IN (
               SELECT unit_id
               FROM   unit_reservations
               WHERE  request_id = p_request_id
           )
      AND  status = 'RESERVED';

    GET DIAGNOSTICS v_released = ROW_COUNT;

    -- ── Delete reservation records ──
    DELETE FROM unit_reservations
    WHERE  request_id = p_request_id;

    GET DIAGNOSTICS v_deleted = ROW_COUNT;

    -- ── Mark request as cancelled ──
    UPDATE blood_requests
    SET    fulfillment_status = 'CANCELLED'
    WHERE  request_id = p_request_id;

    COMMIT;

    RAISE NOTICE 'CANCELLED: Request %. Released % reserved unit(s), '
                 'removed % reservation record(s). Status → CANCELLED.',
                 p_request_id, v_released, v_deleted;
END;
$$;

COMMENT ON PROCEDURE sp_cancel_reservation IS
    'Cancels a blood request and releases all RESERVED (not USED) units back '
    'to AVAILABLE. Reservation records are deleted and the request status '
    'is set to CANCELLED.';


-- ============================================================================
-- 5. PROCEDURE: sp_issue_blood
-- ============================================================================
-- Marks reserved blood units as USED after the hospital physically receives
-- the blood.  Only acts on units with status = 'RESERVED'.
-- ============================================================================

CREATE OR REPLACE PROCEDURE sp_issue_blood(
    p_request_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status fulfillment_status_enum;
    v_issued INT;
BEGIN
    -- ── Validate ──
    SELECT fulfillment_status INTO v_status
    FROM   blood_requests
    WHERE  request_id = p_request_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'REQUEST_NOT_FOUND: Blood request % does not exist.',
                         p_request_id;
    END IF;

    IF v_status NOT IN ('FULFILLED', 'PARTIAL') THEN
        RAISE EXCEPTION 'INVALID_STATUS: Request % has status "%" — only '
                         'FULFILLED or PARTIAL requests can be issued.',
                         p_request_id, v_status;
    END IF;

    -- ── Transition RESERVED → USED ──
    UPDATE blood_units
    SET    status = 'USED'
    WHERE  unit_id IN (
               SELECT unit_id
               FROM   unit_reservations
               WHERE  request_id = p_request_id
           )
      AND  status = 'RESERVED';

    GET DIAGNOSTICS v_issued = ROW_COUNT;

    IF v_issued = 0 THEN
        RAISE EXCEPTION 'NO_RESERVED_UNITS: No reserved units found for '
                         'request %. They may have already been issued.',
                         p_request_id;
    END IF;

    COMMIT;

    RAISE NOTICE 'ISSUED: % unit(s) issued to hospital for request %.',
                 v_issued, p_request_id;
END;
$$;

COMMENT ON PROCEDURE sp_issue_blood IS
    'Issues reserved blood to the requesting hospital. Transitions all '
    'RESERVED units linked to the request to USED status. Does not affect '
    'units that have already been issued.';


-- ============================================================================
-- 6. PROCEDURE: sp_daily_expiry_maintenance
-- ============================================================================
-- Wrapper around the existing sp_expire_stale_units() (from triggers.sql).
-- Designed to be scheduled via pg_cron for daily batch expiration.
-- ============================================================================

CREATE OR REPLACE PROCEDURE sp_daily_expiry_maintenance()
LANGUAGE plpgsql
AS $$
DECLARE
    v_start TIMESTAMPTZ := clock_timestamp();
    v_end   TIMESTAMPTZ;
BEGIN
    RAISE NOTICE '──────── Daily Expiry Maintenance ────────';
    RAISE NOTICE 'Start: %', v_start;

    -- Delegate to the existing batch-expiry procedure from triggers.sql
    CALL sp_expire_stale_units();

    v_end := clock_timestamp();
    RAISE NOTICE 'End: % (duration: % ms)',
        v_end, EXTRACT(MILLISECOND FROM v_end - v_start)::INT;
    RAISE NOTICE '──────────────────────────────────────────';

    COMMIT;
END;
$$;

COMMENT ON PROCEDURE sp_daily_expiry_maintenance IS
    'Daily maintenance wrapper: calls sp_expire_stale_units() to batch-expire '
    'all AVAILABLE blood units past their expiration date. Logs start/end '
    'timestamps. Schedule with pg_cron or application-level scheduler.';


-- ============================================================================
-- 7. FUNCTION: fn_get_available_inventory (Utility)
-- ============================================================================
-- Returns a summary of available blood units grouped by blood type.
-- Optionally filtered by a specific blood group and/or Rh factor.
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_get_available_inventory(
    p_blood_group blood_group_enum DEFAULT NULL,
    p_rh_factor   rh_factor_enum   DEFAULT NULL
)
RETURNS TABLE (
    blood_group     blood_group_enum,
    rh_factor       rh_factor_enum,
    available_units BIGINT,
    earliest_expiry DATE,
    latest_expiry   DATE
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY
    SELECT d.blood_group,
           d.rh_factor,
           COUNT(*)         AS available_units,
           MIN(bu.expiration_date) AS earliest_expiry,
           MAX(bu.expiration_date) AS latest_expiry
    FROM   blood_units bu
    INNER JOIN donors d ON d.donor_id = bu.donor_id
    WHERE  bu.status            = 'AVAILABLE'
      AND  bu.expiration_date  >= CURRENT_DATE
      AND  (p_blood_group IS NULL OR d.blood_group = p_blood_group)
      AND  (p_rh_factor   IS NULL OR d.rh_factor   = p_rh_factor)
    GROUP BY d.blood_group, d.rh_factor
    ORDER BY d.blood_group, d.rh_factor;
END;
$$;

COMMENT ON FUNCTION fn_get_available_inventory IS
    'Returns a summary of available (non-expired) blood units grouped by '
    'blood type. Pass NULL for both parameters to get the full inventory, '
    'or filter by specific blood group and/or Rh factor.';


-- ============================================================================
-- END OF PROCEDURES
-- ============================================================================
