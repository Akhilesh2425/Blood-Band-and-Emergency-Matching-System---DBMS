-- ============================================================================
-- Blood Bank & Emergency Donor-Matching System
-- Trigger Definitions — PostgreSQL
-- ============================================================================
-- PURPOSE:
--   Automatically transition blood units to 'EXPIRED' status when the current
--   date surpasses their expiration_date. Two complementary mechanisms:
--
--   1. ROW-LEVEL TRIGGER  — fires on every INSERT or UPDATE on blood_units,
--      catching units that are past-due the moment they are touched.
--
--   2. MAINTENANCE PROCEDURE — a callable stored procedure that batch-expires
--      all stale AVAILABLE units. Intended to be invoked by pg_cron or an
--      application scheduler (e.g., daily at midnight).
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 0. CLEAN SLATE
-- ────────────────────────────────────────────────────────────────────────────

DROP TRIGGER  IF EXISTS trg_auto_expire_blood_unit ON blood_units;
DROP FUNCTION IF EXISTS fn_auto_expire_blood_unit();
DROP PROCEDURE IF EXISTS sp_expire_stale_units();

-- ────────────────────────────────────────────────────────────────────────────
-- 1. TRIGGER FUNCTION: fn_auto_expire_blood_unit
--    Runs BEFORE INSERT or UPDATE on each row of blood_units.
--    If the unit's expiration_date is in the past AND the unit is still
--    marked AVAILABLE, the function silently changes the status to EXPIRED
--    before the row is committed.
-- ────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_auto_expire_blood_unit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Only act on units that are currently AVAILABLE.
    -- RESERVED or USED units are managed by the reservation workflow.
    IF NEW.status = 'AVAILABLE' AND NEW.expiration_date < CURRENT_DATE THEN
        NEW.status := 'EXPIRED';
        RAISE NOTICE 'Unit % auto-expired (expiration_date: %, current_date: %)',
                      NEW.unit_id, NEW.expiration_date, CURRENT_DATE;
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION fn_auto_expire_blood_unit() IS
    'Trigger function: automatically sets a blood unit''s status to EXPIRED '
    'if its expiration_date is before CURRENT_DATE and the unit is still AVAILABLE.';

-- ────────────────────────────────────────────────────────────────────────────
-- 2. TRIGGER: trg_auto_expire_blood_unit
--    Attached to blood_units. Fires BEFORE INSERT or UPDATE on each row.
--    Using BEFORE (not AFTER) so we can mutate NEW before it is written.
-- ────────────────────────────────────────────────────────────────────────────

CREATE TRIGGER trg_auto_expire_blood_unit
    BEFORE INSERT OR UPDATE
    ON blood_units
    FOR EACH ROW
    EXECUTE FUNCTION fn_auto_expire_blood_unit();

COMMENT ON TRIGGER trg_auto_expire_blood_unit ON blood_units IS
    'Fires before every INSERT/UPDATE on blood_units. Automatically expires '
    'units whose expiration_date has passed while still marked AVAILABLE.';

-- ────────────────────────────────────────────────────────────────────────────
-- 3. STORED PROCEDURE: sp_expire_stale_units
--    Batch-expires all AVAILABLE units whose expiration_date < CURRENT_DATE.
--    Returns the count of affected rows via a RAISE NOTICE.
--
--    Usage (manual or via pg_cron):
--      CALL sp_expire_stale_units();
--
--    The UPDATE will also fire the row-level trigger above, but since both
--    set the same target status ('EXPIRED'), they are idempotent.
-- ────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE PROCEDURE sp_expire_stale_units()
LANGUAGE plpgsql
AS $$
DECLARE
    v_affected INT;
BEGIN
    UPDATE blood_units
       SET status = 'EXPIRED'
     WHERE status = 'AVAILABLE'
       AND expiration_date < CURRENT_DATE;

    GET DIAGNOSTICS v_affected = ROW_COUNT;

    RAISE NOTICE 'sp_expire_stale_units: % unit(s) expired.', v_affected;
END;
$$;

COMMENT ON PROCEDURE sp_expire_stale_units() IS
    'Batch maintenance procedure: expires all AVAILABLE blood units whose '
    'expiration_date has passed. Designed for daily scheduling via pg_cron.';

-- ============================================================================
-- END OF TRIGGERS
-- ============================================================================
