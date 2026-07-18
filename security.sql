-- ============================================================================
-- Blood Bank & Emergency Donor-Matching System
-- Security & Role Management — PostgreSQL
-- ============================================================================
-- PURPOSE:
--   Implements Role-Based Access Control (RBAC) following the principle of
--   least privilege.
--
-- ROLES:
--   1. blood_bank_admin    : Full access to all objects.
--   2. inventory_manager   : Can add/expire units and register donors.
--   3. hospital_client     : Can only view available inventory and insert requests.
--   4. reporting_role      : Read-only access to views and queries.
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 1. Create Roles
-- ────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'blood_bank_admin') THEN
        CREATE ROLE blood_bank_admin WITH NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'inventory_manager') THEN
        CREATE ROLE inventory_manager WITH NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'hospital_client') THEN
        CREATE ROLE hospital_client WITH NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'reporting_role') THEN
        CREATE ROLE reporting_role WITH NOLOGIN;
    END IF;
END
$$;

-- ────────────────────────────────────────────────────────────────────────────
-- 2. Revoke Public Access (Secure by Default)
-- ────────────────────────────────────────────────────────────────────────────
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL PROCEDURES IN SCHEMA public FROM PUBLIC;

-- ────────────────────────────────────────────────────────────────────────────
-- 3. Grant Permissions: blood_bank_admin
-- ────────────────────────────────────────────────────────────────────────────
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO blood_bank_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO blood_bank_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO blood_bank_admin;
GRANT ALL PRIVILEGES ON ALL PROCEDURES IN SCHEMA public TO blood_bank_admin;

-- ────────────────────────────────────────────────────────────────────────────
-- 4. Grant Permissions: inventory_manager
-- ────────────────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE ON donors TO inventory_manager;
GRANT SELECT, INSERT, UPDATE ON blood_units TO inventory_manager;
GRANT SELECT ON hospitals TO inventory_manager;
GRANT SELECT ON blood_requests TO inventory_manager;
GRANT SELECT ON unit_reservations TO inventory_manager;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO inventory_manager;

-- Can execute specific inventory procedures and functions
GRANT EXECUTE ON FUNCTION fn_register_donor TO inventory_manager;
GRANT EXECUTE ON FUNCTION fn_add_blood_unit TO inventory_manager;
GRANT EXECUTE ON FUNCTION fn_get_available_inventory TO inventory_manager;
GRANT EXECUTE ON PROCEDURE sp_reserve_blood_units TO inventory_manager;
GRANT EXECUTE ON PROCEDURE sp_cancel_reservation TO inventory_manager;
GRANT EXECUTE ON PROCEDURE sp_issue_blood TO inventory_manager;
GRANT EXECUTE ON PROCEDURE sp_expire_stale_units TO inventory_manager;
GRANT EXECUTE ON PROCEDURE sp_daily_expiry_maintenance TO inventory_manager;

-- ────────────────────────────────────────────────────────────────────────────
-- 5. Grant Permissions: hospital_client
-- ────────────────────────────────────────────────────────────────────────────
-- Hospitals can view their own profile, submit requests, and check inventory.
GRANT SELECT ON hospitals TO hospital_client;
GRANT SELECT, INSERT ON blood_requests TO hospital_client;
GRANT SELECT ON vw_available_inventory TO hospital_client;
GRANT USAGE, SELECT ON SEQUENCE blood_requests_request_id_seq TO hospital_client;

-- ────────────────────────────────────────────────────────────────────────────
-- 6. Grant Permissions: reporting_role
-- ────────────────────────────────────────────────────────────────────────────
-- Read-only access for dashboards and BI tools
GRANT SELECT ON ALL TABLES IN SCHEMA public TO reporting_role;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO reporting_role;

-- ────────────────────────────────────────────────────────────────────────────
-- 7. Default Privileges for Future Tables
-- ────────────────────────────────────────────────────────────────────────────
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO blood_bank_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO reporting_role;

-- ============================================================================
-- END OF SECURITY POLICIES
-- ============================================================================
