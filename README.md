# Blood Bank & Emergency Donor-Matching System

## Overview

The Blood Bank & Emergency Donor-Matching System is a PostgreSQL-based database project developed to manage blood inventory, donor records, hospital requests, and emergency blood allocation. The system focuses on maintaining data integrity, reducing redundancy, preventing duplicate reservations during concurrent requests, and automatically managing expired blood units.

The project demonstrates practical implementation of advanced Database Management System concepts through a real-world healthcare application.

---

## Problem Statement

Managing blood inventory manually can lead to several issues, including inaccurate stock records, expired blood units remaining in inventory, and multiple hospitals attempting to reserve the same blood unit simultaneously. These problems can delay emergency treatment and compromise data consistency.

This project provides a database solution that ensures efficient blood inventory management, secure reservation of blood units, automatic expiry handling, and safe concurrent access using PostgreSQL transaction management.

---

## Objectives

- Maintain accurate donor information.
- Track the complete lifecycle of blood units.
- Process hospital blood requests efficiently.
- Prevent duplicate reservation of blood units.
- Automatically identify and expire outdated blood units.
- Minimize redundancy through database normalization.
- Demonstrate advanced PostgreSQL database concepts.

---

## Technologies Used

- PostgreSQL 17
- SQL
- PL/pgSQL
- pgAdmin 4
- Mermaid.js
- dbdiagram.io
- Graphviz

---

## Database Features

- Donor registration and management
- Blood inventory tracking
- Hospital registration
- Blood request management
- Blood unit reservation
- Automatic blood expiry
- Stored procedures
- Database triggers
- Views and materialized views
- Transaction management
- Concurrency control
- Analytical SQL queries

---

## Database Design

The database consists of the following core entities:

- Donors
- Blood Units
- Hospitals
- Blood Requests
- Unit Reservations

Relationships are designed using proper primary and foreign keys while maintaining Third Normal Form (3NF) and Boyce-Codd Normal Form (BCNF).

Blood group information is stored only in the Donors table to eliminate redundancy and maintain data consistency.

---

## Advanced DBMS Concepts Implemented

- Entity Relationship Modeling
- Relational Database Design
- Third Normal Form (3NF)
- Boyce-Codd Normal Form (BCNF)
- Primary Keys
- Foreign Keys
- CHECK Constraints
- ENUM Types
- Stored Procedures
- Triggers
- Views
- Materialized Views
- Indexing
- Transactions
- Concurrency Control
- Row-Level Locking using `SELECT ... FOR UPDATE`

---

## Project Structure

```
Blood_Bank_DBMS
│
├── schema.sql
├── triggers.sql
├── procedures.sql
├── queries.sql
├── views.sql
├── seed.sql
├── security.sql
├── functions_test.sql
│
├── README_DATABASE.md
├── README_USAGE.md
├── Blood_Bank_DBMS_Report.pdf
│
└── diagrams
    ├── chen_er_diagram.png
    ├── relational_schema.png
    └── crow_foot_schema.png
```

---

## Installation

Create a PostgreSQL database.

```sql
CREATE DATABASE blood_bank;
```

Execute the SQL files in the following order:

1. schema.sql
2. triggers.sql
3. procedures.sql
4. seed.sql
5. views.sql
6. queries.sql

---

## Concurrency Control

One of the major objectives of this project is preventing race conditions during emergency blood allocation.

The reservation procedure uses PostgreSQL transactions together with `SELECT ... FOR UPDATE` to lock candidate blood units before reservation. This ensures that the same blood unit cannot be reserved by multiple hospitals simultaneously.

An additional UNIQUE constraint on the reservation table provides another level of protection against duplicate allocation.

---

## Future Scope

The project can be extended with:

- Web-based hospital dashboard
- Mobile application for donors
- SMS and email notifications
- Integration with multiple blood banks
- Barcode or QR code tracking
- Predictive analytics for blood demand
- AI-assisted donor recommendation

---

## Author

Akhilesh Gurjigalla

B.Tech, Computer Science and Engineering

National Institute of Technology Warangal

---
