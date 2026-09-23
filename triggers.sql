


DROP TRIGGER  IF EXISTS trg_auto_expire_blood_unit ON blood_units;
DROP FUNCTION IF EXISTS fn_auto_expire_blood_unit();
DROP PROCEDURE IF EXISTS sp_expire_stale_units();



CREATE OR REPLACE FUNCTION fn_auto_expire_blood_unit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    
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


CREATE TRIGGER trg_auto_expire_blood_unit
    BEFORE INSERT OR UPDATE
    ON blood_units
    FOR EACH ROW
    EXECUTE FUNCTION fn_auto_expire_blood_unit();

COMMENT ON TRIGGER trg_auto_expire_blood_unit ON blood_units IS
    'Fires before every INSERT/UPDATE on blood_units. Automatically expires '
    'units whose expiration_date has passed while still marked AVAILABLE.';

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

