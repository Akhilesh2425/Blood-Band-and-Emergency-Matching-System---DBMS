-- ============================================================================
-- Blood Bank & Emergency Donor-Matching System
-- Database Schema (DDL) — PostgreSQL
-- Normalization: Strict 3NF / BCNF
-- ============================================================================
-- DESIGN NOTE:
--   Blood type (blood_group + rh_factor) is stored ONLY on the `donors` table.
--   `blood_units` references the donor via FK, so the blood type is derived
--   through the join — never duplicated. This satisfies 3NF by eliminating
--   the transitive dependency: unit → donor → blood_type.
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 0. CLEAN SLATE — drop existing objects in reverse-dependency order
-- ────────────────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS unit_reservations CASCADE;
DROP TABLE IF EXISTS blood_requests    CASCADE;
DROP TABLE IF EXISTS blood_units       CASCADE;
DROP TABLE IF EXISTS hospitals         CASCADE;
DROP TABLE IF EXISTS donors            CASCADE;

DROP TYPE IF EXISTS blood_group_enum      CASCADE;
DROP TYPE IF EXISTS rh_factor_enum        CASCADE;
DROP TYPE IF EXISTS unit_status_enum      CASCADE;
DROP TYPE IF EXISTS priority_level_enum   CASCADE;
DROP TYPE IF EXISTS urgency_enum          CASCADE;
DROP TYPE IF EXISTS fulfillment_status_enum CASCADE;

-- ────────────────────────────────────────────────────────────────────────────
-- 1. CUSTOM ENUM TYPES — strict domain constraints
-- ────────────────────────────────────────────────────────────────────────────

CREATE TYPE blood_group_enum AS ENUM ('A', 'B', 'AB', 'O');
COMMENT ON TYPE blood_group_enum IS 'ABO blood group classification.';

CREATE TYPE rh_factor_enum AS ENUM ('POSITIVE', 'NEGATIVE');
COMMENT ON TYPE rh_factor_enum IS 'Rhesus factor (Rh+ / Rh−).';

CREATE TYPE unit_status_enum AS ENUM ('AVAILABLE', 'RESERVED', 'USED', 'EXPIRED');
COMMENT ON TYPE unit_status_enum IS 'Lifecycle status of a blood unit.';

CREATE TYPE priority_level_enum AS ENUM ('NORMAL', 'HIGH', 'CRITICAL');
COMMENT ON TYPE priority_level_enum IS 'Hospital priority tier for request triage.';

CREATE TYPE urgency_enum AS ENUM ('ROUTINE', 'URGENT', 'EMERGENCY');
COMMENT ON TYPE urgency_enum IS 'Clinical urgency of a blood request.';

CREATE TYPE fulfillment_status_enum AS ENUM ('PENDING', 'PARTIAL', 'FULFILLED', 'CANCELLED');
COMMENT ON TYPE fulfillment_status_enum IS 'Tracks how much of a blood request has been satisfied.';

-- ────────────────────────────────────────────────────────────────────────────
-- 2. TABLE: donors (Strong Entity)
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE donors (
    donor_id      SERIAL            PRIMARY KEY,
    first_name    VARCHAR(100)      NOT NULL,
    last_name     VARCHAR(100)      NOT NULL,
    date_of_birth DATE              NOT NULL,
    blood_group   blood_group_enum  NOT NULL,
    rh_factor     rh_factor_enum    NOT NULL,
    phone         VARCHAR(20)       NOT NULL  UNIQUE,
    email         VARCHAR(255)      UNIQUE,
    address       TEXT,
    is_active     BOOLEAN           NOT NULL DEFAULT TRUE,
    registered_at TIMESTAMPTZ       NOT NULL DEFAULT NOW(),

    -- Domain constraint: donor must be at least 18 years old at registration
    CONSTRAINT chk_donor_min_age
        CHECK (date_of_birth <= CURRENT_DATE - INTERVAL '18 years')
);

COMMENT ON TABLE  donors              IS 'Registered blood donors with demographics, contact info, and blood type.';
COMMENT ON COLUMN donors.donor_id     IS 'Auto-increment surrogate primary key.';
COMMENT ON COLUMN donors.blood_group  IS 'ABO group — canonical source of truth (not duplicated on blood_units).';
COMMENT ON COLUMN donors.rh_factor    IS 'Rhesus factor — canonical source of truth.';
COMMENT ON COLUMN donors.phone        IS 'Primary contact number; must be unique across donors.';
COMMENT ON COLUMN donors.is_active    IS 'Soft-delete flag. FALSE = donor is deactivated, not physically deleted.';

-- ────────────────────────────────────────────────────────────────────────────
-- 3. TABLE: blood_units (Weak Entity — existence-dependent on donors)
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE blood_units (
    unit_id          SERIAL            PRIMARY KEY,
    donor_id         INT               NOT NULL,
    collection_date  DATE              NOT NULL,
    expiration_date  DATE              NOT NULL,
    status           unit_status_enum  NOT NULL DEFAULT 'AVAILABLE',
    volume_ml        NUMERIC(6, 2)     NOT NULL DEFAULT 450.00,

    created_at       TIMESTAMPTZ       NOT NULL DEFAULT NOW(),

    -- Referential integrity: cascade delete if donor record is purged
    CONSTRAINT fk_blood_units_donor
        FOREIGN KEY (donor_id)
        REFERENCES donors (donor_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    -- Domain constraint: expiration must be after collection
    CONSTRAINT chk_expiration_after_collection
        CHECK (expiration_date > collection_date),

    -- Domain constraint: volume must be positive
    CONSTRAINT chk_positive_volume
        CHECK (volume_ml > 0)
);

COMMENT ON TABLE  blood_units                 IS 'Individual units of collected blood. Blood type is derived via the donor FK (3NF).';
COMMENT ON COLUMN blood_units.unit_id         IS 'Auto-increment surrogate primary key.';
COMMENT ON COLUMN blood_units.donor_id        IS 'FK → donors. Blood group/Rh is resolved through this join.';
COMMENT ON COLUMN blood_units.collection_date IS 'Date the unit was drawn from the donor.';
COMMENT ON COLUMN blood_units.expiration_date IS 'Date after which the unit is no longer viable (typically 42 days for whole blood).';
COMMENT ON COLUMN blood_units.status          IS 'Current lifecycle state: AVAILABLE → RESERVED → USED | EXPIRED.';
COMMENT ON COLUMN blood_units.volume_ml       IS 'Volume of the unit in millilitres. Standard whole-blood donation ≈ 450 mL.';

-- ────────────────────────────────────────────────────────────────────────────
-- 4. TABLE: hospitals (Strong Entity)
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE hospitals (
    hospital_id    SERIAL              PRIMARY KEY,
    name           VARCHAR(255)        NOT NULL,
    license_number VARCHAR(50)         NOT NULL  UNIQUE,
    priority_level priority_level_enum NOT NULL DEFAULT 'NORMAL',
    phone          VARCHAR(20)         NOT NULL,
    email          VARCHAR(255),
    address        TEXT,
    is_active      BOOLEAN             NOT NULL DEFAULT TRUE,
    registered_at  TIMESTAMPTZ         NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  hospitals                  IS 'Registered hospitals that submit blood requests.';
COMMENT ON COLUMN hospitals.hospital_id      IS 'Auto-increment surrogate primary key.';
COMMENT ON COLUMN hospitals.license_number   IS 'Government-issued license; unique identifier for the hospital.';
COMMENT ON COLUMN hospitals.priority_level   IS 'Triage tier: CRITICAL hospitals are served before NORMAL ones.';
COMMENT ON COLUMN hospitals.is_active        IS 'Soft-delete flag. FALSE = hospital is deactivated.';

-- ────────────────────────────────────────────────────────────────────────────
-- 5. TABLE: blood_requests (Weak Entity — existence-dependent on hospitals)
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE blood_requests (
    request_id             SERIAL                   PRIMARY KEY,
    hospital_id            INT                      NOT NULL,
    requested_blood_group  blood_group_enum         NOT NULL,
    requested_rh_factor    rh_factor_enum           NOT NULL,
    quantity               INT                      NOT NULL,
    urgency                urgency_enum             NOT NULL DEFAULT 'ROUTINE',
    fulfillment_status     fulfillment_status_enum  NOT NULL DEFAULT 'PENDING',
    requested_at           TIMESTAMPTZ              NOT NULL DEFAULT NOW(),
    fulfilled_at           TIMESTAMPTZ,

    -- Referential integrity
    CONSTRAINT fk_blood_requests_hospital
        FOREIGN KEY (hospital_id)
        REFERENCES hospitals (hospital_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,      -- do not delete a hospital with active requests

    -- Domain constraint: must request at least 1 unit
    CONSTRAINT chk_quantity_positive
        CHECK (quantity >= 1),

    -- Domain constraint: fulfilled_at must be after requested_at (if set)
    CONSTRAINT chk_fulfilled_after_requested
        CHECK (fulfilled_at IS NULL OR fulfilled_at >= requested_at)
);

COMMENT ON TABLE  blood_requests                        IS 'Hospital requests for blood of a specific type, quantity, and urgency.';
COMMENT ON COLUMN blood_requests.request_id             IS 'Auto-increment surrogate primary key.';
COMMENT ON COLUMN blood_requests.hospital_id            IS 'FK → hospitals. The requesting institution.';
COMMENT ON COLUMN blood_requests.requested_blood_group  IS 'Desired ABO group for the requested blood.';
COMMENT ON COLUMN blood_requests.requested_rh_factor    IS 'Desired Rh factor for the requested blood.';
COMMENT ON COLUMN blood_requests.quantity               IS 'Number of units requested (≥ 1).';
COMMENT ON COLUMN blood_requests.urgency                IS 'Clinical urgency: ROUTINE < URGENT < EMERGENCY.';
COMMENT ON COLUMN blood_requests.fulfillment_status     IS 'Tracks progress: PENDING → PARTIAL → FULFILLED | CANCELLED.';
COMMENT ON COLUMN blood_requests.fulfilled_at           IS 'Timestamp when the request was fully satisfied (NULL while pending).';

-- ────────────────────────────────────────────────────────────────────────────
-- 6. TABLE: unit_reservations (Associative / Junction Entity)
--    Maps specific blood units to specific requests.
--    The UNIQUE constraint on unit_id is the CRITICAL anti-double-booking guard.
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE unit_reservations (
    reservation_id SERIAL      PRIMARY KEY,
    unit_id        INT         NOT NULL,
    request_id     INT         NOT NULL,
    reserved_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Referential integrity
    CONSTRAINT fk_reservations_unit
        FOREIGN KEY (unit_id)
        REFERENCES blood_units (unit_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,      -- do not delete a unit that has been reserved

    CONSTRAINT fk_reservations_request
        FOREIGN KEY (request_id)
        REFERENCES blood_requests (request_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE        -- if a request is cancelled, release its reservations
);

COMMENT ON TABLE  unit_reservations                IS 'Junction table mapping individual blood units to the request they fulfill. The UNIQUE index on unit_id prevents double-booking.';
COMMENT ON COLUMN unit_reservations.reservation_id IS 'Auto-increment surrogate primary key.';
COMMENT ON COLUMN unit_reservations.unit_id        IS 'FK → blood_units. Each unit can appear here AT MOST ONCE (enforced by unique index).';
COMMENT ON COLUMN unit_reservations.request_id     IS 'FK → blood_requests. The request this unit is allocated to.';
COMMENT ON COLUMN unit_reservations.reserved_at    IS 'Timestamp when the reservation was created.';

-- ────────────────────────────────────────────────────────────────────────────
-- 7. UNIQUE INDEX — ANTI-DOUBLE-BOOKING GUARD
--    Ensures a single blood unit can never be reserved by two concurrent
--    transactions.  PostgreSQL will acquire a row-level lock on this unique
--    index during INSERT, serialising competing reservations.
-- ────────────────────────────────────────────────────────────────────────────

CREATE UNIQUE INDEX uq_reservation_unit
    ON unit_reservations (unit_id);

COMMENT ON INDEX uq_reservation_unit IS
    'Guarantees one-to-one: a blood unit may be reserved at most once. '
    'Concurrent INSERTs targeting the same unit_id will block on this index, '
    'preventing race-condition double-booking.';

-- ────────────────────────────────────────────────────────────────────────────
-- 8. PERFORMANCE INDEXES — optimise frequent query patterns
-- ────────────────────────────────────────────────────────────────────────────

-- Donor lookups by blood type (used during donor-matching)
CREATE INDEX idx_donors_blood_type
    ON donors (blood_group, rh_factor);

-- Blood unit queries: find available units of a specific type that haven't expired
-- (joins blood_units ↔ donors on donor_id, filters on status & expiration_date)
CREATE INDEX idx_blood_units_status
    ON blood_units (status);

CREATE INDEX idx_blood_units_expiration
    ON blood_units (expiration_date);

CREATE INDEX idx_blood_units_donor
    ON blood_units (donor_id);

-- Request lookups: find pending requests for a blood type
CREATE INDEX idx_requests_blood_type
    ON blood_requests (requested_blood_group, requested_rh_factor);

CREATE INDEX idx_requests_fulfillment
    ON blood_requests (fulfillment_status);

CREATE INDEX idx_requests_urgency
    ON blood_requests (urgency);

-- Reservation lookups by request (to count how many units are allocated)
CREATE INDEX idx_reservations_request
    ON unit_reservations (request_id);

-- ============================================================================
-- END OF SCHEMA DDL
-- ============================================================================
