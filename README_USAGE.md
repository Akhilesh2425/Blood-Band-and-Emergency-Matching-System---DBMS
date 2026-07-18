# Blood Bank & Emergency Donor-Matching System — Usage Guide

## Complete PostgreSQL Database Reference

---

## Table of Contents

1. [Installation](#installation)
2. [Execution Order](#execution-order)
3. [Schema Reference](#schema-reference)
4. [Triggers](#triggers)
5. [Stored Procedures & Functions](#stored-procedures--functions)
6. [Views](#views)
7. [Indexes](#indexes)
8. [Transaction Management](#transaction-management)
9. [FOR UPDATE Locking](#for-update-locking)
10. [Race-Condition Prevention](#race-condition-prevention)
11. [Normalization — 3NF / BCNF](#normalization--3nf--bcnf)
12. [Concurrency Model](#concurrency-model)
13. [Testing](#testing)
14. [Expected Outputs](#expected-outputs)
15. [File Inventory](#file-inventory)

---

## Installation

### Prerequisites

- **PostgreSQL 14+** (procedures with transaction control require PG 11+; features like `FILTER` require PG 9.4+)
- A terminal with `psql` available
- Superuser or database-owner privileges

### Create the Database

```bash
createdb blood_bank_db
```

Or via `psql`:

```sql
CREATE DATABASE blood_bank_db
    WITH ENCODING = 'UTF8'
         LC_COLLATE = 'en_US.UTF-8'
         LC_CTYPE = 'en_US.UTF-8';
```

---

## Execution Order

**Files must be executed in strict dependency order:**

```
┌──────────────┐
│  schema.sql  │  ← ENUMs, tables, FKs, CHECK constraints, indexes
└──────┬───────┘
       │
┌──────▼────────┐
│ triggers.sql  │  ← Auto-expiry trigger + batch procedure
└──────┬────────┘
       │
┌──────▼──────────┐
│ procedures.sql  │  ← Stored procedures & functions
└──────┬──────────┘
       │
┌──────▼───────┐
│  seed.sql    │  ← Sample data (40 donors, 150 units, etc.)
└──────┬───────┘
       │
┌──────▼───────┐
│  views.sql   │  ← Reusable views & materialized views
└──────┬───────┘
       │
┌──────▼─────────┐
│  queries.sql   │  ← Analytical queries (read-only)
└────────────────┘
```

### One-Line Installation

```bash
for f in schema.sql triggers.sql procedures.sql seed.sql views.sql; do
    psql -U postgres -d blood_bank_db -f "$f"
done
```

### Windows PowerShell

```powershell
foreach ($f in @("schema.sql","triggers.sql","procedures.sql","seed.sql","views.sql")) {
    psql -U postgres -d blood_bank_db -f $f
}
```

### Testing (separate database recommended)

```bash
# Run on a fresh database to avoid conflicts with seed data
psql -U postgres -d blood_bank_test -f schema.sql
psql -U postgres -d blood_bank_test -f triggers.sql
psql -U postgres -d blood_bank_test -f procedures.sql
psql -U postgres -d blood_bank_test -f functions_test.sql
```

---

## Schema Reference

### ENUM Types

| Type | Values | Used In |
|------|--------|---------|
| `blood_group_enum` | `A`, `B`, `AB`, `O` | `donors.blood_group`, `blood_requests.requested_blood_group` |
| `rh_factor_enum` | `POSITIVE`, `NEGATIVE` | `donors.rh_factor`, `blood_requests.requested_rh_factor` |
| `unit_status_enum` | `AVAILABLE`, `RESERVED`, `USED`, `EXPIRED` | `blood_units.status` |
| `priority_level_enum` | `NORMAL`, `HIGH`, `CRITICAL` | `hospitals.priority_level` |
| `urgency_enum` | `ROUTINE`, `URGENT`, `EMERGENCY` | `blood_requests.urgency` |
| `fulfillment_status_enum` | `PENDING`, `PARTIAL`, `FULFILLED`, `CANCELLED` | `blood_requests.fulfillment_status` |

### Tables

#### `donors` (Strong Entity)
| Column | Type | Constraints |
|--------|------|-------------|
| `donor_id` | `SERIAL PK` | Auto-increment |
| `first_name` | `VARCHAR(100)` | NOT NULL |
| `last_name` | `VARCHAR(100)` | NOT NULL |
| `date_of_birth` | `DATE` | NOT NULL, CHECK ≥ 18 years old |
| `blood_group` | `blood_group_enum` | NOT NULL — **canonical source** |
| `rh_factor` | `rh_factor_enum` | NOT NULL — **canonical source** |
| `phone` | `VARCHAR(20)` | NOT NULL, UNIQUE |
| `email` | `VARCHAR(255)` | UNIQUE |
| `address` | `TEXT` | Optional |
| `is_active` | `BOOLEAN` | NOT NULL, DEFAULT TRUE |
| `registered_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() |

#### `blood_units` (Weak Entity → depends on `donors`)
| Column | Type | Constraints |
|--------|------|-------------|
| `unit_id` | `SERIAL PK` | Auto-increment |
| `donor_id` | `INT FK` | → `donors(donor_id)` CASCADE |
| `collection_date` | `DATE` | NOT NULL |
| `expiration_date` | `DATE` | NOT NULL, CHECK > collection_date |
| `status` | `unit_status_enum` | NOT NULL, DEFAULT 'AVAILABLE' |
| `volume_ml` | `NUMERIC(6,2)` | NOT NULL, DEFAULT 450.00, CHECK > 0 |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() |

> **3NF Design**: Blood type is NOT stored on `blood_units`. To determine a unit's blood type, JOIN to `donors` via `donor_id`.

#### `hospitals` (Strong Entity)
| Column | Type | Constraints |
|--------|------|-------------|
| `hospital_id` | `SERIAL PK` | Auto-increment |
| `name` | `VARCHAR(255)` | NOT NULL |
| `license_number` | `VARCHAR(50)` | NOT NULL, UNIQUE |
| `priority_level` | `priority_level_enum` | NOT NULL, DEFAULT 'NORMAL' |
| `phone` | `VARCHAR(20)` | NOT NULL |
| `email` | `VARCHAR(255)` | Optional |
| `address` | `TEXT` | Optional |
| `is_active` | `BOOLEAN` | NOT NULL, DEFAULT TRUE |
| `registered_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() |

#### `blood_requests` (Weak Entity → depends on `hospitals`)
| Column | Type | Constraints |
|--------|------|-------------|
| `request_id` | `SERIAL PK` | Auto-increment |
| `hospital_id` | `INT FK` | → `hospitals(hospital_id)` RESTRICT |
| `requested_blood_group` | `blood_group_enum` | NOT NULL |
| `requested_rh_factor` | `rh_factor_enum` | NOT NULL |
| `quantity` | `INT` | NOT NULL, CHECK ≥ 1 |
| `urgency` | `urgency_enum` | NOT NULL, DEFAULT 'ROUTINE' |
| `fulfillment_status` | `fulfillment_status_enum` | NOT NULL, DEFAULT 'PENDING' |
| `requested_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() |
| `fulfilled_at` | `TIMESTAMPTZ` | CHECK ≥ requested_at |

#### `unit_reservations` (Junction Entity)
| Column | Type | Constraints |
|--------|------|-------------|
| `reservation_id` | `SERIAL PK` | Auto-increment |
| `unit_id` | `INT FK` | → `blood_units(unit_id)` RESTRICT |
| `request_id` | `INT FK` | → `blood_requests(request_id)` CASCADE |
| `reserved_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() |

> **Anti-Double-Booking**: `UNIQUE INDEX uq_reservation_unit ON unit_reservations(unit_id)` ensures each blood unit is reserved at most once.

---

## Triggers

### `trg_auto_expire_blood_unit`
- **Type**: `BEFORE INSERT OR UPDATE` on `blood_units`, `FOR EACH ROW`
- **Function**: `fn_auto_expire_blood_unit()`
- **Logic**: If `NEW.status = 'AVAILABLE'` AND `NEW.expiration_date < CURRENT_DATE` → `NEW.status := 'EXPIRED'`
- **Purpose**: Automatically catches expired units the moment they are touched

### `sp_expire_stale_units()` (Batch maintenance)
- **Type**: Stored procedure (defined in `triggers.sql`)
- **Usage**: `CALL sp_expire_stale_units();`
- **Purpose**: Sweeps entire `blood_units` table, expires all stale AVAILABLE units
- **Scheduling**: Run daily via `pg_cron`

---

## Stored Procedures & Functions

### Functions (return values)

#### `fn_register_donor()`
```sql
SELECT fn_register_donor(
    'Aarav',               -- first_name
    'Sharma',              -- last_name
    '1990-03-15',          -- date_of_birth
    'O',                   -- blood_group (ENUM: A, B, AB, O)
    'POSITIVE',            -- rh_factor (ENUM: POSITIVE, NEGATIVE)
    '+91-9876543210',      -- phone (UNIQUE)
    'aarav@email.com',     -- email (optional, UNIQUE)
    '12 MG Road, Bengaluru' -- address (optional)
);
-- Returns: INT (new donor_id)
```

#### `fn_add_blood_unit()`
```sql
SELECT fn_add_blood_unit(
    1,                     -- donor_id
    CURRENT_DATE,          -- collection_date (default: today)
    450.00,                -- volume_ml (default: 450)
    42                     -- shelf_life_days (default: 42)
);
-- Returns: INT (new unit_id)
-- Expiration auto-calculated as collection_date + shelf_life_days
```

#### `fn_get_available_inventory()`
```sql
-- All blood types
SELECT * FROM fn_get_available_inventory();

-- Specific blood type
SELECT * FROM fn_get_available_inventory('O', 'POSITIVE');

-- Returns TABLE: blood_group, rh_factor, available_units, earliest_expiry, latest_expiry
```

### Procedures (manage transactions)

#### `sp_reserve_blood_units()` — **Critical Path**
```sql
-- All-or-nothing (default): ROLLBACK if insufficient units
CALL sp_reserve_blood_units(42);

-- Partial fulfillment allowed: reserve what's available
CALL sp_reserve_blood_units(42, TRUE);
```

**Internal flow**:
1. Validates request status (must be PENDING or PARTIAL)
2. `SELECT ... FOR UPDATE OF bu` locks matching AVAILABLE units
3. Reserves up to `quantity` units (FIFO by expiration date)
4. `COMMIT` on success, `ROLLBACK` on failure
5. Updates `fulfillment_status` to FULFILLED or PARTIAL

#### `sp_cancel_reservation()`
```sql
CALL sp_cancel_reservation(42);
-- Releases RESERVED units → AVAILABLE
-- Deletes reservation records
-- Sets request status → CANCELLED
```

#### `sp_issue_blood()`
```sql
CALL sp_issue_blood(42);
-- Transitions RESERVED units → USED
-- Only works on FULFILLED or PARTIAL requests
```

#### `sp_daily_expiry_maintenance()`
```sql
CALL sp_daily_expiry_maintenance();
-- Wrapper: calls sp_expire_stale_units()
-- Logs start/end timestamps
-- Schedule via pg_cron: '0 0 * * *'
```

---

## Views

### Standard Views (real-time)

| View | Purpose |
|------|---------|
| `vw_available_inventory` | Available units by blood type |
| `vw_hospital_statistics` | Per-hospital request counts & fulfillment rates |
| `vw_monthly_donations` | Monthly collection aggregates |
| `vw_donor_statistics` | Donor activity, donation counts, status |
| `vw_blood_group_summary` | Blood type distribution among donors |
| `vw_request_summary` | All requests with progress & urgency ranking |
| `vw_reservation_summary` | Full reservation audit trail (5-table join) |
| `vw_expiry_dashboard` | Expiry monitoring with urgency tiers |
| `vw_hospital_demand` | Outstanding demand per hospital per blood type |
| `vw_blood_utilization` | Utilization and wastage rates by blood type |

### Materialized Views (snapshots)

| View | Refresh Command |
|------|----------------|
| `mv_inventory_dashboard` | `REFRESH MATERIALIZED VIEW mv_inventory_dashboard;` |
| `mv_monthly_report` | `REFRESH MATERIALIZED VIEW mv_monthly_report;` |

**Usage example**:
```sql
SELECT * FROM vw_available_inventory;
SELECT * FROM vw_hospital_statistics;
SELECT * FROM vw_expiry_dashboard WHERE expiry_tier = 'CRITICAL';
```

---

## Indexes

### Performance Indexes
| Index | Columns | Purpose |
|-------|---------|---------|
| `idx_donors_blood_type` | `(blood_group, rh_factor)` | Donor matching |
| `idx_blood_units_status` | `(status)` | Filter by unit status |
| `idx_blood_units_expiration` | `(expiration_date)` | Expiry checks |
| `idx_blood_units_donor` | `(donor_id)` | JOIN optimization |
| `idx_requests_blood_type` | `(requested_blood_group, requested_rh_factor)` | Request matching |
| `idx_requests_fulfillment` | `(fulfillment_status)` | Dashboard queries |
| `idx_requests_urgency` | `(urgency)` | Priority triage |
| `idx_reservations_request` | `(request_id)` | Count allocations |

### Integrity Index
| Index | Type | Purpose |
|-------|------|---------|
| `uq_reservation_unit` | `UNIQUE (unit_id)` | **Anti-double-booking guard** |

---

## Transaction Management

### How Procedures Use Transactions

```
CALL sp_reserve_blood_units(request_id)
│
├── BEGIN (implicit — PostgreSQL starts a transaction)
│   │
│   ├── SELECT request details
│   ├── SELECT ... FOR UPDATE (acquire row locks)
│   ├── UPDATE blood_units SET status = 'RESERVED'
│   ├── INSERT INTO unit_reservations
│   │
│   ├── IF success:
│   │   ├── UPDATE blood_requests SET status = 'FULFILLED'
│   │   └── COMMIT ✓  (all changes persisted, locks released)
│   │
│   └── IF failure:
│       ├── ROLLBACK ✗  (all changes undone, locks released)
│       └── RAISE EXCEPTION (error propagated to caller)
```

### Key Principles

1. **Atomicity**: Either all units are reserved or none (all-or-nothing mode)
2. **Consistency**: ENUMs, CHECKs, FKs, and UNIQUE constraints enforced at all times
3. **Isolation**: `FOR UPDATE` locks prevent concurrent transactions from seeing stale data
4. **Durability**: `COMMIT` guarantees changes survive crashes

---

## FOR UPDATE Locking

### What It Does

```sql
SELECT bu.unit_id
FROM   blood_units bu
INNER JOIN donors d ON d.donor_id = bu.donor_id
WHERE  bu.status = 'AVAILABLE'
ORDER BY bu.expiration_date ASC
FOR UPDATE OF bu        -- ← Exclusive row-level lock on blood_units rows
LIMIT  5;
```

- Acquires an **exclusive row-level lock** on each matching `blood_units` row
- Other transactions trying to lock the same rows will **block** (wait)
- Locks are held until `COMMIT` or `ROLLBACK`
- Ensures no two transactions can reserve the same unit simultaneously

### Locking Behaviour in READ COMMITTED

| Event | Transaction A | Transaction B |
|-------|--------------|--------------|
| T1 | `FOR UPDATE` → locks units 1,2,3 | |
| T2 | Updates unit 1,2 → RESERVED | |
| T3 | | `FOR UPDATE` → **BLOCKS** on unit 1 |
| T4 | `COMMIT` → releases locks | |
| T5 | | Lock acquired. **Re-checks WHERE** |
| T6 | | Units 1,2 = RESERVED → **skipped** |
| T7 | | Only unit 3 is AVAILABLE → locked |

---

## Race-Condition Prevention

### Five Layers of Defence

| Layer | Mechanism | What It Prevents |
|-------|-----------|-----------------|
| 1 | `SELECT ... FOR UPDATE` | Concurrent access to same rows |
| 2 | READ COMMITTED re-evaluation | Stale reads after lock acquisition |
| 3 | `UNIQUE INDEX uq_reservation_unit` | Double-booking at database level |
| 4 | ENUM type constraints | Invalid status values |
| 5 | CHECK constraints | Domain rule violations |

---

## Normalization — 3NF / BCNF

### Design Principle

**Blood type (`blood_group` + `rh_factor`) is stored ONLY on the `donors` table.**

To determine a blood unit's type:
```sql
SELECT d.blood_group, d.rh_factor
FROM   blood_units bu
INNER JOIN donors d ON d.donor_id = bu.donor_id
WHERE  bu.unit_id = 42;
```

### Why Not Store Blood Type on `blood_units`?

If blood type were duplicated on `blood_units`:
- **Update anomaly**: Correcting a donor's blood type would require updating every related unit
- **Insertion anomaly**: A unit could be inserted with a blood type different from its donor
- **Deletion anomaly**: Deleting all units would lose the donor's blood type information

By storing it only on `donors`, every non-key attribute depends on **the key, the whole key, and nothing but the key** — satisfying 3NF and BCNF.

---

## Concurrency Model

### PostgreSQL Default: READ COMMITTED

- Each SQL statement sees only data committed before the **statement** began
- `FOR UPDATE` locks cause blocking and re-evaluation after lock acquisition
- This is sufficient for the blood bank's concurrency requirements

### Recommended pg_cron Schedule

```sql
-- Daily expiry maintenance at midnight
SELECT cron.schedule('blood-expiry', '0 0 * * *',
    'CALL sp_daily_expiry_maintenance()');

-- Refresh materialized views every 15 minutes
SELECT cron.schedule('refresh-dashboard', '*/15 * * * *',
    'REFRESH MATERIALIZED VIEW mv_inventory_dashboard');

SELECT cron.schedule('refresh-monthly', '0 * * * *',
    'REFRESH MATERIALIZED VIEW mv_monthly_report');
```

---

## Testing

### Run the Test Suite

```bash
# On a fresh test database (recommended)
createdb blood_bank_test
psql -U postgres -d blood_bank_test -f schema.sql
psql -U postgres -d blood_bank_test -f triggers.sql
psql -U postgres -d blood_bank_test -f procedures.sql
psql -U postgres -d blood_bank_test -f functions_test.sql
```

### What Gets Tested

| Test | Component | Validates |
|------|-----------|-----------|
| 1 | `fn_register_donor()` | Insert, duplicate rejection, age validation |
| 2 | `fn_add_blood_unit()` | Insert, expiry calculation, invalid donor rejection |
| 3 | `trg_auto_expire_blood_unit` | Auto-expiry on insert of past-due unit |
| 4 | `sp_reserve_blood_units()` | FOR UPDATE locking, COMMIT on success |
| 5 | `sp_cancel_reservation()` | Unit release, reservation deletion |
| 6 | `sp_issue_blood()` | RESERVED → USED transition |
| 7 | `sp_daily_expiry_maintenance()` | Batch expiry wrapper |
| 8 | `fn_get_available_inventory()` | Full and filtered inventory queries |

---

## Expected Outputs

### Successful Donor Registration
```
NOTICE:  REGISTERED: Donor "Rajiv Menon" (ID: 41, Blood: O POSITIVE)
```

### Successful Blood Collection
```
NOTICE:  COLLECTED: Unit ID 151 from Donor ID 1 (collected: 2026-07-09, expires: 2026-08-20)
```

### Successful Reservation (all-or-nothing)
```
NOTICE:  FULFILLED: All 3 unit(s) reserved for request 41. Status → FULFILLED.
```

### Failed Reservation (insufficient units)
```
ERROR:  INSUFFICIENT_UNITS: Needed 5 units of O POSITIVE, only 2 available.
        All-or-nothing mode — transaction rolled back, no units were reserved.
```

### Successful Cancellation
```
NOTICE:  CANCELLED: Request 41. Released 3 reserved unit(s), removed 3 reservation record(s). Status → CANCELLED.
```

### Successful Blood Issuance
```
NOTICE:  ISSUED: 3 unit(s) issued to hospital for request 41.
```

### Auto-Expiry Trigger
```
NOTICE:  Unit 151 auto-expired (expiration_date: 2026-05-10, current_date: 2026-07-09)
```

### Daily Maintenance
```
NOTICE:  ──────── Daily Expiry Maintenance ────────
NOTICE:  Start: 2026-07-09 00:00:01.234+05:30
NOTICE:  sp_expire_stale_units: 0 unit(s) expired.
NOTICE:  End: 2026-07-09 00:00:01.256+05:30 (duration: 22 ms)
NOTICE:  ──────────────────────────────────────────
```

---

## File Inventory

| File | Lines | Purpose | Phase |
|------|-------|---------|-------|
| `schema.sql` | 264 | DDL: ENUMs, tables, FKs, CHECKs, indexes | Day 1 |
| `triggers.sql` | 106 | Auto-expiry trigger + batch procedure | Day 1 |
| `procedures.sql` | 527 | 7 stored procedures/functions | Day 1 |
| `README_DATABASE.md` | — | Architecture documentation | Day 1 |
| `seed.sql` | — | 40 donors, 150 units, 10 hospitals, 40 requests, 80 reservations | Day 2 |
| `queries.sql` | — | 32 advanced analytical SQL queries | Day 2 |
| `views.sql` | — | 10 views + 2 materialized views | Day 2 |
| `functions_test.sql` | — | 8 comprehensive function/procedure tests | Day 2 |
| `README_USAGE.md` | — | This usage guide | Day 2 |
