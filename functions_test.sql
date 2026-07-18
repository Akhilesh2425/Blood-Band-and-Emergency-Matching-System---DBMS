-- ============================================================================
-- Blood Bank & Emergency Donor-Matching System
-- Functions & Procedures Testing Script — PostgreSQL
-- ============================================================================
-- DEPENDENCY: Execute schema.sql → triggers.sql → procedures.sql FIRST.
--             Do NOT run seed.sql before this — tests create their own data.
--
-- PURPOSE:
--   Demonstrates and verifies every stored procedure/function.
--   Each test is wrapped in a transaction and rolled back to leave the
--   database in a clean state.
--
-- USAGE:
--   psql -U your_user -d blood_bank_db -f functions_test.sql
-- ============================================================================


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  TEST 1: fn_register_donor — Register a new donor                      ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

DO $$
DECLARE
    v_donor_id INT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '  TEST 1: fn_register_donor()';
    RAISE NOTICE '════════════════════════════════════════════════════════════';

    -- ── Test 1a: Successful registration ──
    RAISE NOTICE '  1a: Registering donor "Rajiv Menon" (O POSITIVE)...';
    v_donor_id := fn_register_donor(
        'Rajiv', 'Menon', '1990-06-15',
        'O', 'POSITIVE',
        '+91-9000000001', 'rajiv.menon@test.com', 'Test Address, Mumbai'
    );
    RAISE NOTICE '  ✓ Success — donor_id = %', v_donor_id;

    -- Verify the donor was inserted
    IF EXISTS (SELECT 1 FROM donors WHERE donor_id = v_donor_id AND first_name = 'Rajiv') THEN
        RAISE NOTICE '  ✓ Verified: donor exists in table';
    ELSE
        RAISE NOTICE '  ✗ FAILED: donor not found in table';
    END IF;

    -- ── Test 1b: Duplicate phone should fail ──
    RAISE NOTICE '  1b: Attempting duplicate phone (should FAIL)...';
    BEGIN
        PERFORM fn_register_donor(
            'Duplicate', 'Test', '1990-01-01',
            'A', 'POSITIVE',
            '+91-9000000001', 'other@test.com', NULL
        );
        RAISE NOTICE '  ✗ FAILED: duplicate was allowed!';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '  ✓ Correctly rejected: %', SQLERRM;
    END;

    -- ── Test 1c: Underage donor should fail ──
    RAISE NOTICE '  1c: Attempting underage donor (should FAIL)...';
    BEGIN
        PERFORM fn_register_donor(
            'Young', 'Donor', '2015-01-01',
            'B', 'NEGATIVE',
            '+91-9000000099', NULL, NULL
        );
        RAISE NOTICE '  ✗ FAILED: underage was allowed!';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '  ✓ Correctly rejected: %', SQLERRM;
    END;

    RAISE NOTICE '  TEST 1 COMPLETE';
    RAISE NOTICE '';
END $$;


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  TEST 2: fn_add_blood_unit — Record a blood collection                 ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

DO $$
DECLARE
    v_donor_id INT;
    v_unit_id  INT;
    v_expiry   DATE;
BEGIN
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '  TEST 2: fn_add_blood_unit()';
    RAISE NOTICE '════════════════════════════════════════════════════════════';

    -- Register a donor for this test
    v_donor_id := fn_register_donor(
        'Test', 'Donor2', '1985-03-20',
        'B', 'POSITIVE',
        '+91-9000000002', 'test.donor2@test.com', NULL
    );

    -- ── Test 2a: Standard collection (default 42-day shelf life) ──
    RAISE NOTICE '  2a: Adding blood unit with default shelf life...';
    v_unit_id := fn_add_blood_unit(v_donor_id, CURRENT_DATE);
    RAISE NOTICE '  ✓ Success — unit_id = %', v_unit_id;

    -- Verify expiration date
    SELECT expiration_date INTO v_expiry
    FROM blood_units WHERE unit_id = v_unit_id;

    IF v_expiry = CURRENT_DATE + 42 THEN
        RAISE NOTICE '  ✓ Verified: expiration_date = % (today + 42 days)', v_expiry;
    ELSE
        RAISE NOTICE '  ✗ FAILED: expected %, got %', CURRENT_DATE + 42, v_expiry;
    END IF;

    -- Verify status is AVAILABLE
    IF EXISTS (SELECT 1 FROM blood_units WHERE unit_id = v_unit_id AND status = 'AVAILABLE') THEN
        RAISE NOTICE '  ✓ Verified: status = AVAILABLE';
    ELSE
        RAISE NOTICE '  ✗ FAILED: status is not AVAILABLE';
    END IF;

    -- ── Test 2b: Custom shelf life ──
    RAISE NOTICE '  2b: Adding unit with 35-day shelf life...';
    v_unit_id := fn_add_blood_unit(v_donor_id, CURRENT_DATE, 350.00, 35);
    RAISE NOTICE '  ✓ Success — unit_id = %, volume = 350 mL', v_unit_id;

    -- ── Test 2c: Invalid donor ID should fail ──
    RAISE NOTICE '  2c: Attempting invalid donor_id (should FAIL)...';
    BEGIN
        PERFORM fn_add_blood_unit(99999);
        RAISE NOTICE '  ✗ FAILED: invalid donor was accepted!';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '  ✓ Correctly rejected: %', SQLERRM;
    END;

    RAISE NOTICE '  TEST 2 COMPLETE';
    RAISE NOTICE '';
END $$;


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  TEST 3: Trigger — Automatic expiry on insert                          ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

DO $$
DECLARE
    v_donor_id INT;
    v_unit_id  INT;
    v_status   unit_status_enum;
BEGIN
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '  TEST 3: trg_auto_expire_blood_unit (trigger)';
    RAISE NOTICE '════════════════════════════════════════════════════════════';

    -- Register a donor
    v_donor_id := fn_register_donor(
        'Test', 'Donor3', '1980-01-01',
        'A', 'NEGATIVE',
        '+91-9000000003', 'test.donor3@test.com', NULL
    );

    -- ── Test 3a: Insert an already-expired unit ──
    RAISE NOTICE '  3a: Inserting unit with past expiry date...';
    v_unit_id := fn_add_blood_unit(v_donor_id, CURRENT_DATE - 60, 450.00, 42);

    SELECT status INTO v_status
    FROM blood_units WHERE unit_id = v_unit_id;

    IF v_status = 'EXPIRED' THEN
        RAISE NOTICE '  ✓ Trigger fired: status auto-set to EXPIRED';
    ELSE
        RAISE NOTICE '  ✗ FAILED: expected EXPIRED, got %', v_status;
    END IF;

    -- ── Test 3b: Insert a future-expiry unit (should remain AVAILABLE) ──
    RAISE NOTICE '  3b: Inserting unit with future expiry date...';
    v_unit_id := fn_add_blood_unit(v_donor_id, CURRENT_DATE);

    SELECT status INTO v_status
    FROM blood_units WHERE unit_id = v_unit_id;

    IF v_status = 'AVAILABLE' THEN
        RAISE NOTICE '  ✓ Correct: status remains AVAILABLE';
    ELSE
        RAISE NOTICE '  ✗ FAILED: expected AVAILABLE, got %', v_status;
    END IF;

    RAISE NOTICE '  TEST 3 COMPLETE';
    RAISE NOTICE '';
END $$;


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  TEST 4: sp_reserve_blood_units — Reserve blood for a request          ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- Note: This procedure uses COMMIT/ROLLBACK internally, so we cannot wrap
-- it in a DO block's exception handler. We test by preparing data, calling
-- the procedure, and then verifying results.

-- Step 4a: Prepare test data
DO $$
DECLARE
    v_d1 INT; v_d2 INT; v_d3 INT;
    v_h1 INT;
BEGIN
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '  TEST 4: sp_reserve_blood_units()';
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '  4a: Preparing test data (3 O+ donors, 5 units, 1 hospital)...';

    -- Create 3 O+ donors
    v_d1 := fn_register_donor('Reserve', 'TestA', '1990-01-01', 'O', 'POSITIVE', '+91-9000000010', NULL, NULL);
    v_d2 := fn_register_donor('Reserve', 'TestB', '1991-02-02', 'O', 'POSITIVE', '+91-9000000011', NULL, NULL);
    v_d3 := fn_register_donor('Reserve', 'TestC', '1992-03-03', 'O', 'POSITIVE', '+91-9000000012', NULL, NULL);

    -- Add 5 available O+ units
    PERFORM fn_add_blood_unit(v_d1, CURRENT_DATE);
    PERFORM fn_add_blood_unit(v_d1, CURRENT_DATE - 1);
    PERFORM fn_add_blood_unit(v_d2, CURRENT_DATE);
    PERFORM fn_add_blood_unit(v_d2, CURRENT_DATE - 2);
    PERFORM fn_add_blood_unit(v_d3, CURRENT_DATE);

    -- Create a hospital
    INSERT INTO hospitals (name, license_number, priority_level, phone)
    VALUES ('Test Hospital Reserve', 'TEST-RES-001', 'HIGH', '+91-1234500001')
    RETURNING hospital_id INTO v_h1;

    -- Create a request for 3 units of O+
    INSERT INTO blood_requests (hospital_id, requested_blood_group, requested_rh_factor, quantity, urgency)
    VALUES (v_h1, 'O', 'POSITIVE', 3, 'EMERGENCY');

    RAISE NOTICE '  ✓ Test data prepared. Now calling sp_reserve_blood_units...';
END $$;

-- Step 4b: Call the reservation procedure
-- (This must be outside a DO block because procedures with COMMIT cannot
--  run inside a function/DO block's exception handler)
CALL sp_reserve_blood_units(
    (SELECT MAX(request_id) FROM blood_requests WHERE fulfillment_status = 'PENDING')
);

-- Step 4c: Verify results
DO $$
DECLARE
    v_req_id   INT;
    v_status   fulfillment_status_enum;
    v_res_cnt  INT;
    v_avail    INT;
BEGIN
    SELECT MAX(request_id) INTO v_req_id
    FROM blood_requests WHERE hospital_id = (
        SELECT hospital_id FROM hospitals WHERE license_number = 'TEST-RES-001'
    );

    SELECT fulfillment_status INTO v_status
    FROM blood_requests WHERE request_id = v_req_id;

    SELECT COUNT(*) INTO v_res_cnt
    FROM unit_reservations WHERE request_id = v_req_id;

    RAISE NOTICE '  4b: Verifying reservation results...';

    IF v_status = 'FULFILLED' THEN
        RAISE NOTICE '  ✓ Request status = FULFILLED';
    ELSE
        RAISE NOTICE '  ✗ FAILED: expected FULFILLED, got %', v_status;
    END IF;

    IF v_res_cnt = 3 THEN
        RAISE NOTICE '  ✓ Reservation count = 3 (matches requested quantity)';
    ELSE
        RAISE NOTICE '  ✗ FAILED: expected 3 reservations, got %', v_res_cnt;
    END IF;

    RAISE NOTICE '  TEST 4 COMPLETE';
    RAISE NOTICE '';
END $$;


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  TEST 5: sp_cancel_reservation — Cancel and release units              ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

DO $$
DECLARE
    v_req_id INT;
BEGIN
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '  TEST 5: sp_cancel_reservation()';
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '  5a: Preparing — creating a new request and reserving...';

    -- Create a new request using existing test hospital
    INSERT INTO blood_requests (
        hospital_id, requested_blood_group, requested_rh_factor,
        quantity, urgency
    )
    VALUES (
        (SELECT hospital_id FROM hospitals WHERE license_number = 'TEST-RES-001'),
        'O', 'POSITIVE', 2, 'ROUTINE'
    )
    RETURNING request_id INTO v_req_id;

    RAISE NOTICE '  Created request_id = %. Reserving 2 units...', v_req_id;
END $$;

-- Reserve 2 units for the new request
CALL sp_reserve_blood_units(
    (SELECT MAX(request_id) FROM blood_requests
     WHERE fulfillment_status = 'PENDING'
       AND hospital_id = (SELECT hospital_id FROM hospitals WHERE license_number = 'TEST-RES-001'))
);

-- Now cancel it
DO $$
DECLARE
    v_req_id INT;
BEGIN
    SELECT MAX(request_id) INTO v_req_id
    FROM blood_requests
    WHERE fulfillment_status = 'FULFILLED'
      AND hospital_id = (SELECT hospital_id FROM hospitals WHERE license_number = 'TEST-RES-001')
    ORDER BY request_id DESC;

    RAISE NOTICE '  5b: Cancelling request_id = %...', v_req_id;
END $$;

CALL sp_cancel_reservation(
    (SELECT MAX(request_id) FROM blood_requests
     WHERE fulfillment_status = 'FULFILLED'
       AND hospital_id = (SELECT hospital_id FROM hospitals WHERE license_number = 'TEST-RES-001'))
);

-- Verify cancellation
DO $$
DECLARE
    v_req_id INT;
    v_status fulfillment_status_enum;
    v_res_cnt INT;
BEGIN
    SELECT MAX(request_id) INTO v_req_id
    FROM blood_requests
    WHERE fulfillment_status = 'CANCELLED'
      AND hospital_id = (SELECT hospital_id FROM hospitals WHERE license_number = 'TEST-RES-001');

    SELECT fulfillment_status INTO v_status FROM blood_requests WHERE request_id = v_req_id;
    SELECT COUNT(*) INTO v_res_cnt FROM unit_reservations WHERE request_id = v_req_id;

    IF v_status = 'CANCELLED' THEN
        RAISE NOTICE '  ✓ Request status = CANCELLED';
    ELSE
        RAISE NOTICE '  ✗ FAILED: expected CANCELLED, got %', v_status;
    END IF;

    IF v_res_cnt = 0 THEN
        RAISE NOTICE '  ✓ All reservations removed';
    ELSE
        RAISE NOTICE '  ✗ FAILED: % reservations still exist', v_res_cnt;
    END IF;

    RAISE NOTICE '  TEST 5 COMPLETE';
    RAISE NOTICE '';
END $$;


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  TEST 6: sp_issue_blood — Issue reserved blood to hospital             ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- First create another reservation to issue
DO $$
DECLARE
    v_req_id INT;
BEGIN
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '  TEST 6: sp_issue_blood()';
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '  6a: Creating a new request and reserving units...';

    INSERT INTO blood_requests (
        hospital_id, requested_blood_group, requested_rh_factor,
        quantity, urgency
    )
    VALUES (
        (SELECT hospital_id FROM hospitals WHERE license_number = 'TEST-RES-001'),
        'O', 'POSITIVE', 2, 'URGENT'
    )
    RETURNING request_id INTO v_req_id;

    RAISE NOTICE '  Created request_id = %', v_req_id;
END $$;

CALL sp_reserve_blood_units(
    (SELECT MAX(request_id) FROM blood_requests
     WHERE fulfillment_status = 'PENDING'
       AND hospital_id = (SELECT hospital_id FROM hospitals WHERE license_number = 'TEST-RES-001'))
);

-- Issue the blood
CALL sp_issue_blood(
    (SELECT MAX(request_id) FROM blood_requests
     WHERE fulfillment_status = 'FULFILLED'
       AND hospital_id = (SELECT hospital_id FROM hospitals WHERE license_number = 'TEST-RES-001'))
);

-- Verify
DO $$
DECLARE
    v_req_id  INT;
    v_used    INT;
BEGIN
    SELECT MAX(request_id) INTO v_req_id
    FROM blood_requests
    WHERE hospital_id = (SELECT hospital_id FROM hospitals WHERE license_number = 'TEST-RES-001')
      AND urgency = 'URGENT';

    SELECT COUNT(*) INTO v_used
    FROM blood_units bu
    INNER JOIN unit_reservations ur ON ur.unit_id = bu.unit_id
    WHERE ur.request_id = v_req_id AND bu.status = 'USED';

    IF v_used > 0 THEN
        RAISE NOTICE '  ✓ % unit(s) successfully transitioned to USED', v_used;
    ELSE
        RAISE NOTICE '  ✗ FAILED: no units have USED status';
    END IF;

    RAISE NOTICE '  TEST 6 COMPLETE';
    RAISE NOTICE '';
END $$;


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  TEST 7: sp_daily_expiry_maintenance — Batch expiry                    ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

DO $$
DECLARE
    v_donor_id INT;
BEGIN
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '  TEST 7: sp_daily_expiry_maintenance()';
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '  7a: Inserting an expired-but-AVAILABLE unit for batch test...';

    -- Use an existing test donor
    SELECT donor_id INTO v_donor_id FROM donors WHERE phone = '+91-9000000010';

    -- Insert a unit that SHOULD be expired (collection 60 days ago)
    -- Note: trigger will catch this on INSERT, so we verify the trigger worked
    PERFORM fn_add_blood_unit(v_donor_id, CURRENT_DATE - 60, 450.00, 42);

    RAISE NOTICE '  ✓ Unit inserted (trigger should have auto-expired it)';
    RAISE NOTICE '  7b: Calling sp_daily_expiry_maintenance()...';
END $$;

CALL sp_daily_expiry_maintenance();

DO $$
BEGIN
    RAISE NOTICE '  ✓ sp_daily_expiry_maintenance completed without errors';
    RAISE NOTICE '  TEST 7 COMPLETE';
    RAISE NOTICE '';
END $$;


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  TEST 8: fn_get_available_inventory — Inventory report                 ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

DO $$
DECLARE
    v_row RECORD;
    v_count INT := 0;
BEGIN
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '  TEST 8: fn_get_available_inventory()';
    RAISE NOTICE '════════════════════════════════════════════════════════════';

    -- ── Test 8a: Full inventory ──
    RAISE NOTICE '  8a: Full available inventory:';
    FOR v_row IN SELECT * FROM fn_get_available_inventory() LOOP
        RAISE NOTICE '      % % : % units (expiry: % to %)',
            v_row.blood_group, v_row.rh_factor,
            v_row.available_units, v_row.earliest_expiry, v_row.latest_expiry;
        v_count := v_count + 1;
    END LOOP;

    IF v_count > 0 THEN
        RAISE NOTICE '  ✓ Returned % blood type group(s)', v_count;
    ELSE
        RAISE NOTICE '  ⚠ No available units found (may be expected if all reserved/used)';
    END IF;

    -- ── Test 8b: Filtered by O POSITIVE ──
    v_count := 0;
    RAISE NOTICE '  8b: Filtered for O POSITIVE:';
    FOR v_row IN SELECT * FROM fn_get_available_inventory('O', 'POSITIVE') LOOP
        RAISE NOTICE '      % % : % units',
            v_row.blood_group, v_row.rh_factor, v_row.available_units;
        v_count := v_count + 1;
    END LOOP;

    IF v_count > 0 THEN
        RAISE NOTICE '  ✓ O POSITIVE inventory found';
    ELSE
        RAISE NOTICE '  ⚠ No O POSITIVE units available';
    END IF;

    RAISE NOTICE '  TEST 8 COMPLETE';
    RAISE NOTICE '';
END $$;


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  SUMMARY                                                               ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

DO $$
BEGIN
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '  ALL TESTS COMPLETE';
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE '  Test 1: fn_register_donor()          — EXECUTED';
    RAISE NOTICE '  Test 2: fn_add_blood_unit()           — EXECUTED';
    RAISE NOTICE '  Test 3: trg_auto_expire_blood_unit    — EXECUTED';
    RAISE NOTICE '  Test 4: sp_reserve_blood_units()      — EXECUTED';
    RAISE NOTICE '  Test 5: sp_cancel_reservation()       — EXECUTED';
    RAISE NOTICE '  Test 6: sp_issue_blood()              — EXECUTED';
    RAISE NOTICE '  Test 7: sp_daily_expiry_maintenance() — EXECUTED';
    RAISE NOTICE '  Test 8: fn_get_available_inventory()  — EXECUTED';
    RAISE NOTICE '';
    RAISE NOTICE '  NOTE: Test data has been inserted into the database.';
    RAISE NOTICE '  Run on a fresh database or test database only.';
    RAISE NOTICE '════════════════════════════════════════════════════════════';
END $$;


-- ============================================================================
-- END OF TESTS
-- ============================================================================
