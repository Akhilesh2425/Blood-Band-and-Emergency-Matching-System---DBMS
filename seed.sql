

BEGIN;

INSERT INTO donors (donor_id, first_name, last_name, date_of_birth, blood_group, rh_factor, phone, email, address, is_active, registered_at)
VALUES
-- ── O POSITIVE (donors 1-10) ──
( 1, 'Aarav',    'Sharma',     '1990-03-15', 'O', 'POSITIVE', '+91-9876543201', 'aarav.sharma@email.com',    '12 MG Road, Bengaluru, Karnataka',           TRUE, '2024-01-15 10:30:00+05:30'),
( 2, 'Arjun',    'Patel',      '1988-07-22', 'O', 'POSITIVE', '+91-9876543202', 'arjun.patel@email.com',     '45 SG Highway, Ahmedabad, Gujarat',          TRUE, '2024-02-20 11:00:00+05:30'),
( 3, 'Vivaan',   'Kumar',      '1995-11-03', 'O', 'POSITIVE', '+91-9876543203', 'vivaan.kumar@email.com',    '78 Connaught Place, New Delhi',               TRUE, '2024-03-10 09:15:00+05:30'),
( 4, 'Aditya',   'Singh',      '1992-05-28', 'O', 'POSITIVE', '+91-9876543204', 'aditya.singh@email.com',    '23 Civil Lines, Lucknow, Uttar Pradesh',      TRUE, '2024-04-05 14:30:00+05:30'),
( 5, 'Rohan',    'Reddy',      '1985-09-14', 'O', 'POSITIVE', '+91-9876543205', 'rohan.reddy@email.com',     '56 Jubilee Hills, Hyderabad, Telangana',      TRUE, '2024-05-12 10:00:00+05:30'),
( 6, 'Karthik',  'Nair',       '1991-01-30', 'O', 'POSITIVE', '+91-9876543206', 'karthik.nair@email.com',    '89 Marine Drive, Kochi, Kerala',              TRUE, '2024-06-18 11:45:00+05:30'),
( 7, 'Ishaan',   'Gupta',      '1993-08-07', 'O', 'POSITIVE', '+91-9876543207', 'ishaan.gupta@email.com',    '34 Rajpur Road, Dehradun, Uttarakhand',       TRUE, '2024-07-22 08:30:00+05:30'),
( 8, 'Pranav',   'Joshi',      '1987-12-19', 'O', 'POSITIVE', '+91-9876543208', 'pranav.joshi@email.com',    '67 FC Road, Pune, Maharashtra',               TRUE, '2024-08-14 13:00:00+05:30'),
( 9, 'Dhruv',    'Deshmukh',   '1994-04-25', 'O', 'POSITIVE', '+91-9876543209', 'dhruv.deshmukh@email.com',  '12 Law Garden, Ahmedabad, Gujarat',           TRUE, '2024-09-03 10:15:00+05:30'),
(10, 'Sai',      'Iyer',       '1989-06-11', 'O', 'POSITIVE', '+91-9876543210', 'sai.iyer@email.com',        '45 T Nagar, Chennai, Tamil Nadu',             TRUE, '2024-10-01 09:00:00+05:30'),

-- ── B POSITIVE (donors 11-18) ──
(11, 'Vikram',   'Verma',      '1990-02-14', 'B', 'POSITIVE', '+91-9876543211', 'vikram.verma@email.com',    '23 Sector 17, Chandigarh',                    TRUE, '2024-01-25 10:30:00+05:30'),
(12, 'Rahul',    'Kapoor',     '1986-10-08', 'B', 'POSITIVE', '+91-9876543212', 'rahul.kapoor@email.com',    '56 Park Street, Kolkata, West Bengal',         TRUE, '2024-02-15 11:00:00+05:30'),
(13, 'Amit',     'Malhotra',   '1993-03-21', 'B', 'POSITIVE', '+91-9876543213', 'amit.malhotra@email.com',   '89 Brigade Road, Bengaluru, Karnataka',       TRUE, '2024-03-20 09:45:00+05:30'),
(14, 'Suresh',   'Chopra',     '1988-11-17', 'B', 'POSITIVE', '+91-9876543214', 'suresh.chopra@email.com',   '12 Mall Road, Shimla, Himachal Pradesh',       TRUE, '2024-04-10 14:00:00+05:30'),
(15, 'Rajesh',   'Bose',       '1991-07-04', 'B', 'POSITIVE', '+91-9876543215', 'rajesh.bose@email.com',     '34 Salt Lake, Kolkata, West Bengal',           TRUE, '2024-05-22 10:30:00+05:30'),
(16, 'Nikhil',   'Mukherjee',  '1995-01-29', 'B', 'POSITIVE', '+91-9876543216', 'nikhil.mukherjee@email.com','67 Ballygunge, Kolkata, West Bengal',          TRUE, '2024-06-14 11:15:00+05:30'),
(17, 'Deepak',   'Pillai',     '1987-09-13', 'B', 'POSITIVE', '+91-9876543217', 'deepak.pillai@email.com',   '89 MG Road, Thiruvananthapuram, Kerala',       TRUE, '2024-07-08 08:45:00+05:30'),
(18, 'Manish',   'Menon',      '1992-05-06', 'B', 'POSITIVE', '+91-9876543218', 'manish.menon@email.com',    '23 Residency Road, Bengaluru, Karnataka',     TRUE, '2024-08-19 13:30:00+05:30'),

-- ── A POSITIVE (donors 19-25) ──
(19, 'Varun',    'Rao',        '1994-08-23', 'A', 'POSITIVE', '+91-9876543219', 'varun.rao@email.com',       '56 Banjara Hills, Hyderabad, Telangana',      TRUE, '2024-09-15 10:00:00+05:30'),
(20, 'Akash',    'Agarwal',    '1989-12-01', 'A', 'POSITIVE', '+91-9876543220', 'akash.agarwal@email.com',   '78 Hazratganj, Lucknow, Uttar Pradesh',       TRUE, '2024-10-10 09:30:00+05:30'),
(21, 'Priya',    'Chauhan',    '1996-04-18', 'A', 'POSITIVE', '+91-9876543221', 'priya.chauhan@email.com',   '12 Sector 22, Noida, Uttar Pradesh',          TRUE, '2024-11-05 11:00:00+05:30'),
(22, 'Ananya',   'Thakur',     '1991-10-30', 'A', 'POSITIVE', '+91-9876543222', 'ananya.thakur@email.com',   '34 Aundh, Pune, Maharashtra',                 TRUE, '2024-11-20 10:15:00+05:30'),
(23, 'Diya',     'Kulkarni',   '1993-06-15', 'A', 'POSITIVE', '+91-9876543223', 'diya.kulkarni@email.com',   '56 Koregaon Park, Pune, Maharashtra',          TRUE, '2024-12-01 09:00:00+05:30'),
(24, 'Kavya',    'Mehta',      '1988-02-27', 'A', 'POSITIVE', '+91-9876543224', 'kavya.mehta@email.com',     '78 CG Road, Ahmedabad, Gujarat',              TRUE, '2025-01-10 14:30:00+05:30'),
(25, 'Riya',     'Sinha',      '1995-09-09', 'A', 'POSITIVE', '+91-9876543225', 'riya.sinha@email.com',      '23 Boring Road, Patna, Bihar',                TRUE, '2025-02-14 10:30:00+05:30'),

-- ── AB POSITIVE (donors 26-29) ──
(26, 'Sneha',    'Banerjee',   '1990-11-12', 'AB', 'POSITIVE', '+91-9876543226', 'sneha.banerjee@email.com', '45 Lake Town, Kolkata, West Bengal',           TRUE, '2025-01-20 11:00:00+05:30'),
(27, 'Neha',     'Mishra',     '1992-03-08', 'AB', 'POSITIVE', '+91-9876543227', 'neha.mishra@email.com',    '67 Gomti Nagar, Lucknow, Uttar Pradesh',      TRUE, '2025-02-05 09:15:00+05:30'),
(28, 'Meera',    'Tiwari',     '1987-07-24', 'AB', 'POSITIVE', '+91-9876543228', 'meera.tiwari@email.com',   '89 Vaishali Nagar, Jaipur, Rajasthan',        TRUE, '2025-03-12 10:45:00+05:30'),
(29, 'Pooja',    'Pandey',     '1994-01-16', 'AB', 'POSITIVE', '+91-9876543229', 'pooja.pandey@email.com',   '12 Ashok Nagar, Bhopal, Madhya Pradesh',      TRUE, '2025-04-08 08:30:00+05:30'),

-- ── O NEGATIVE (donors 30-33) ──
(30, 'Ishita',   'Saxena',     '1991-05-20', 'O', 'NEGATIVE', '+91-9876543230', 'ishita.saxena@email.com',   '34 Aliganj, Lucknow, Uttar Pradesh',          TRUE, '2025-01-15 13:00:00+05:30'),
(31, 'Divya',    'Deshpande',  '1989-08-03', 'O', 'NEGATIVE', '+91-9876543231', 'divya.deshpande@email.com', '56 Kothrud, Pune, Maharashtra',               TRUE, '2025-02-22 10:15:00+05:30'),
(32, 'Shruti',   'Khanna',     '1993-12-28', 'O', 'NEGATIVE', '+91-9876543232', 'shruti.khanna@email.com',   '78 Rajouri Garden, New Delhi',                TRUE, '2025-03-18 09:00:00+05:30'),
(33, 'Lakshmi',  'Bhatt',      '1986-04-14', 'O', 'NEGATIVE', '+91-9876543233', 'lakshmi.bhatt@email.com',   '23 Navrangpura, Ahmedabad, Gujarat',          TRUE, '2025-04-25 14:30:00+05:30'),

-- ── B NEGATIVE (donors 34-36) ──
(34, 'Nisha',    'Kohli',      '1992-09-07', 'B', 'NEGATIVE', '+91-9876543234', 'nisha.kohli@email.com',     '45 Saket, New Delhi',                         TRUE, '2025-03-01 10:30:00+05:30'),
(35, 'Aisha',    'Gandhi',     '1990-06-22', 'B', 'NEGATIVE', '+91-9876543235', 'aisha.gandhi@email.com',    '67 Paldi, Ahmedabad, Gujarat',                TRUE, '2025-03-15 11:00:00+05:30'),
(36, 'Saanvi',   'Dubey',      '1995-02-11', 'B', 'NEGATIVE', '+91-9876543236', 'saanvi.dubey@email.com',    '89 Indira Nagar, Bengaluru, Karnataka',        TRUE, '2025-04-02 09:45:00+05:30'),

-- ── A NEGATIVE (donors 37-38) ──
(37, 'Myra',     'Yadav',      '1993-10-19', 'A', 'NEGATIVE', '+91-9876543237', 'myra.yadav@email.com',      '12 Vasant Kunj, New Delhi',                   TRUE, '2025-04-18 10:00:00+05:30'),
(38, 'Sara',     'Jain',       '1988-01-05', 'A', 'NEGATIVE', '+91-9876543238', 'sara.jain@email.com',       '34 Malviya Nagar, Jaipur, Rajasthan',         TRUE, '2025-05-10 08:30:00+05:30'),

-- ── AB NEGATIVE (donors 39-40) ──
(39, 'Aadhya',   'Shah',       '1991-07-28', 'AB', 'NEGATIVE', '+91-9876543239', 'aadhya.shah@email.com',    '56 Bodakdev, Ahmedabad, Gujarat',             TRUE, '2025-05-20 13:00:00+05:30'),
(40, 'Tara',     'Hegde',      '1994-11-14', 'AB', 'NEGATIVE', '+91-9876543240', 'tara.hegde@email.com',     '78 Jayanagar, Bengaluru, Karnataka',           TRUE, '2025-06-01 10:15:00+05:30');


INSERT INTO hospitals (hospital_id, name, license_number, priority_level, phone, email, address, is_active, registered_at)
VALUES
( 1, 'Apollo Hospitals Bengaluru',           'KA-HOSP-2024-001', 'CRITICAL', '+91-8044443201', 'admin@apollo-blr.in',       '154/11 Bannerghatta Road, Bengaluru',          TRUE, '2024-01-10 09:00:00+05:30'),
( 2, 'Fortis Memorial Research Institute',   'HR-HOSP-2024-002', 'CRITICAL', '+91-1244443202', 'admin@fortis-gurgaon.in',   'Sector 44, Gurugram, Haryana',                  TRUE, '2024-02-15 10:00:00+05:30'),
( 3, 'Medanta - The Medicity',               'HR-HOSP-2024-003', 'HIGH',     '+91-1244443203', 'admin@medanta.org',         'CH Baktawar Singh Road, Gurugram, Haryana',     TRUE, '2024-03-20 11:00:00+05:30'),
( 4, 'AIIMS New Delhi',                      'DL-HOSP-2024-004', 'HIGH',     '+91-1126594204', 'admin@aiims.edu',           'Sri Aurobindo Marg, Ansari Nagar, New Delhi',   TRUE, '2024-04-05 09:30:00+05:30'),
( 5, 'Narayana Health Bengaluru',            'KA-HOSP-2024-005', 'HIGH',     '+91-8066243205', 'admin@narayanahealth.org',  '258/A Bommasandra, Bengaluru',                  TRUE, '2024-05-12 10:30:00+05:30'),
( 6, 'Kokilaben Dhirubhai Ambani Hospital',  'MH-HOSP-2024-006', 'NORMAL',   '+91-2230943206', 'admin@kokilaben.com',       'Rao Saheb Achutrao Patwardhan Marg, Mumbai',    TRUE, '2024-06-18 11:00:00+05:30'),
( 7, 'CMC Vellore',                          'TN-HOSP-2024-007', 'NORMAL',   '+91-4162283207', 'admin@cmcvellore.ac.in',    'Ida Scudder Road, Vellore, Tamil Nadu',          TRUE, '2024-07-22 09:15:00+05:30'),
( 8, 'Manipal Hospitals Jaipur',             'RJ-HOSP-2024-008', 'NORMAL',   '+91-1414043208', 'admin@manipal-jaipur.in',   'Sector 5, Vidhyadhar Nagar, Jaipur',            TRUE, '2024-08-14 10:00:00+05:30'),
( 9, 'Lilavati Hospital Mumbai',             'MH-HOSP-2024-009', 'NORMAL',   '+91-2226751209', 'admin@lilavati.com',        'A-791 Bandra Reclamation, Bandra West, Mumbai', TRUE, '2024-09-03 11:30:00+05:30'),
(10, 'KIMS Thiruvananthapuram',              'KL-HOSP-2024-010', 'NORMAL',   '+91-4712447210', 'admin@kimstvm.com',         'PB No 1, Anayara PO, Thiruvananthapuram',       TRUE, '2024-10-01 09:00:00+05:30');


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       ((gs - 1) % 10) + 1,
       DATE '2026-06-10' + (gs - 1),
       DATE '2026-06-10' + (gs - 1) + 42,
       'AVAILABLE'::unit_status_enum,
       450.00
FROM generate_series(1, 15) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       ((gs - 16) % 8) + 11,
       DATE '2026-06-12' + (gs - 16),
       DATE '2026-06-12' + (gs - 16) + 42,
       'AVAILABLE'::unit_status_enum,
       450.00
FROM generate_series(16, 25) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       ((gs - 26) % 7) + 19,
       DATE '2026-06-14' + (gs - 26),
       DATE '2026-06-14' + (gs - 26) + 42,
       'AVAILABLE'::unit_status_enum,
       450.00
FROM generate_series(26, 35) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       ((gs - 36) % 4) + 26,
       DATE '2026-06-16' + (gs - 36),
       DATE '2026-06-16' + (gs - 36) + 42,
       'AVAILABLE'::unit_status_enum,
       450.00
FROM generate_series(36, 40) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       ((gs - 41) % 4) + 30,
       DATE '2026-06-18' + (gs - 41),
       DATE '2026-06-18' + (gs - 41) + 42,
       'AVAILABLE'::unit_status_enum,
       450.00
FROM generate_series(41, 45) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       ((gs - 46) % 3) + 34,
       DATE '2026-06-20' + (gs - 46),
       DATE '2026-06-20' + (gs - 46) + 42,
       'AVAILABLE'::unit_status_enum,
       450.00
FROM generate_series(46, 48) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       ((gs - 49) % 2) + 37,
       DATE '2026-06-22' + (gs - 49),
       DATE '2026-06-22' + (gs - 49) + 42,
       'AVAILABLE'::unit_status_enum,
       450.00
FROM generate_series(49, 50) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       ((gs - 51) % 10) + 1,
       DATE '2026-06-05' + ((gs - 51) % 15),
       DATE '2026-06-05' + ((gs - 51) % 15) + 42,
       'RESERVED'::unit_status_enum,
       450.00
FROM generate_series(51, 70) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       ((gs - 71) % 8) + 11,
       DATE '2026-06-07' + ((gs - 71) % 12),
       DATE '2026-06-07' + ((gs - 71) % 12) + 42,
       'RESERVED'::unit_status_enum,
       450.00
FROM generate_series(71, 82) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       ((gs - 83) % 7) + 19,
       DATE '2026-06-09' + ((gs - 83) % 8),
       DATE '2026-06-09' + ((gs - 83) % 8) + 42,
       'RESERVED'::unit_status_enum,
       450.00
FROM generate_series(83, 90) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       ((gs - 91) % 4) + 26,
       DATE '2026-06-11' + (gs - 91),
       DATE '2026-06-11' + (gs - 91) + 42,
       'RESERVED'::unit_status_enum,
       450.00
FROM generate_series(91, 94) gs;

INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       ((gs - 95) % 4) + 30,
       DATE '2026-06-13' + (gs - 95),
       DATE '2026-06-13' + (gs - 95) + 42,
       'RESERVED'::unit_status_enum,
       450.00
FROM generate_series(95, 100) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       ((gs - 101) % 3) + 34,
       DATE '2026-06-15' + (gs - 101),
       DATE '2026-06-15' + (gs - 101) + 42,
       'RESERVED'::unit_status_enum,
       450.00
FROM generate_series(101, 105) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       ((gs - 106) % 2) + 37,
       DATE '2026-06-17' + (gs - 106),
       DATE '2026-06-17' + (gs - 106) + 42,
       'RESERVED'::unit_status_enum,
       450.00
FROM generate_series(106, 108) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       ((gs - 109) % 2) + 39,
       DATE '2026-06-19' + (gs - 109),
       DATE '2026-06-19' + (gs - 109) + 42,
       'RESERVED'::unit_status_enum,
       450.00
FROM generate_series(109, 110) gs;



INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       gs - 110,
       DATE '2026-05-01' + ((gs - 111) * 2),
       DATE '2026-05-01' + ((gs - 111) * 2) + 42,
       'USED'::unit_status_enum,
       450.00
FROM generate_series(111, 120) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       gs - 110,
       DATE '2026-05-05' + ((gs - 121) * 2),
       DATE '2026-05-05' + ((gs - 121) * 2) + 42,
       'USED'::unit_status_enum,
       450.00
FROM generate_series(121, 125) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       gs - 107,
       DATE '2026-05-10' + ((gs - 126) * 2),
       DATE '2026-05-10' + ((gs - 126) * 2) + 42,
       'USED'::unit_status_enum,
       450.00
FROM generate_series(126, 128) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       gs - 99,
       DATE '2026-05-15' + ((gs - 129) * 3),
       DATE '2026-05-15' + ((gs - 129) * 3) + 42,
       'USED'::unit_status_enum,
       450.00
FROM generate_series(129, 130) gs;



INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       gs - 130,
       DATE '2026-01-05' + ((gs - 131) * 3),
       DATE '2026-01-05' + ((gs - 131) * 3) + 42,
       'EXPIRED'::unit_status_enum,
       450.00
FROM generate_series(131, 138) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       gs - 128,
       DATE '2026-01-20' + ((gs - 139) * 4),
       DATE '2026-01-20' + ((gs - 139) * 4) + 42,
       'EXPIRED'::unit_status_enum,
       450.00
FROM generate_series(139, 143) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       gs - 125,
       DATE '2026-02-01' + ((gs - 144) * 5),
       DATE '2026-02-01' + ((gs - 144) * 5) + 42,
       'EXPIRED'::unit_status_enum,
       450.00
FROM generate_series(144, 147) gs;


INSERT INTO blood_units (unit_id, donor_id, collection_date, expiration_date, status, volume_ml)
SELECT gs,
       CASE WHEN (gs - 148) % 2 = 0 THEN 39 ELSE 40 END,
       DATE '2026-02-10' + ((gs - 148) * 4),
       DATE '2026-02-10' + ((gs - 148) * 4) + 42,
       'EXPIRED'::unit_status_enum,
       450.00
FROM generate_series(148, 150) gs;



INSERT INTO blood_requests (request_id, hospital_id, requested_blood_group, requested_rh_factor, quantity, urgency, fulfillment_status, requested_at, fulfilled_at)
VALUES
       
( 1,  1, 'O',  'POSITIVE',  3, 'EMERGENCY', 'FULFILLED', '2026-05-10 08:00:00+05:30', '2026-05-10 08:45:00+05:30'),
( 2,  2, 'O',  'POSITIVE',  3, 'URGENT',    'FULFILLED', '2026-05-12 09:00:00+05:30', '2026-05-12 09:30:00+05:30'),
( 3,  3, 'O',  'POSITIVE',  4, 'EMERGENCY', 'FULFILLED', '2026-05-14 10:00:00+05:30', '2026-05-14 10:20:00+05:30'),
( 4,  4, 'B',  'POSITIVE',  3, 'URGENT',    'FULFILLED', '2026-05-16 11:00:00+05:30', '2026-05-16 11:15:00+05:30'),
( 5,  5, 'B',  'POSITIVE',  2, 'ROUTINE',   'FULFILLED', '2026-05-18 14:00:00+05:30', '2026-05-18 14:30:00+05:30'),
( 6,  6, 'A',  'POSITIVE',  3, 'URGENT',    'FULFILLED', '2026-05-20 09:30:00+05:30', '2026-05-20 10:00:00+05:30'),
( 7,  7, 'O',  'NEGATIVE',  2, 'EMERGENCY', 'FULFILLED', '2026-05-22 07:00:00+05:30', '2026-05-22 07:20:00+05:30'),
       
( 8,  8, 'O',  'POSITIVE',  5, 'ROUTINE',   'FULFILLED', '2026-06-10 10:00:00+05:30', '2026-06-10 10:30:00+05:30'),
( 9,  9, 'O',  'POSITIVE',  5, 'URGENT',    'FULFILLED', '2026-06-11 11:00:00+05:30', '2026-06-11 11:20:00+05:30'),
(10, 10, 'O',  'POSITIVE',  5, 'ROUTINE',   'FULFILLED', '2026-06-12 09:00:00+05:30', '2026-06-12 09:15:00+05:30'),
(11,  1, 'O',  'POSITIVE',  5, 'EMERGENCY', 'FULFILLED', '2026-06-13 08:30:00+05:30', '2026-06-13 08:50:00+05:30'),
(12,  2, 'B',  'POSITIVE',  4, 'ROUTINE',   'FULFILLED', '2026-06-14 10:00:00+05:30', '2026-06-14 10:25:00+05:30'),
(13,  3, 'B',  'POSITIVE',  4, 'URGENT',    'FULFILLED', '2026-06-15 11:30:00+05:30', '2026-06-15 11:45:00+05:30'),
(14,  4, 'B',  'POSITIVE',  4, 'ROUTINE',   'FULFILLED', '2026-06-16 09:00:00+05:30', '2026-06-16 09:20:00+05:30'),
(15,  5, 'A',  'POSITIVE',  4, 'URGENT',    'FULFILLED', '2026-06-17 10:30:00+05:30', '2026-06-17 10:50:00+05:30'),
(16,  6, 'A',  'POSITIVE',  4, 'EMERGENCY', 'FULFILLED', '2026-06-18 08:00:00+05:30', '2026-06-18 08:15:00+05:30'),
(17,  7, 'AB', 'POSITIVE',  4, 'ROUTINE',   'FULFILLED', '2026-06-19 14:00:00+05:30', '2026-06-19 14:30:00+05:30'),

       
(18,  8, 'O',  'NEGATIVE',  6, 'EMERGENCY', 'PARTIAL',   '2026-06-20 07:30:00+05:30', NULL),
(19,  9, 'O',  'NEGATIVE',  4, 'URGENT',    'PARTIAL',   '2026-06-21 09:00:00+05:30', NULL),
(20, 10, 'B',  'NEGATIVE',  8, 'EMERGENCY', 'PARTIAL',   '2026-06-22 08:00:00+05:30', NULL),
(21,  1, 'A',  'NEGATIVE',  5, 'URGENT',    'PARTIAL',   '2026-06-23 10:00:00+05:30', NULL),
(22,  2, 'AB', 'NEGATIVE',  4, 'EMERGENCY', 'PARTIAL',   '2026-06-24 07:00:00+05:30', NULL),

       
(23,  3, 'O',  'POSITIVE',  3, 'ROUTINE',   'PENDING',   '2026-07-01 10:00:00+05:30', NULL),
(24,  4, 'B',  'POSITIVE',  2, 'URGENT',    'PENDING',   '2026-07-01 11:00:00+05:30', NULL),
(25,  5, 'A',  'POSITIVE',  4, 'EMERGENCY', 'PENDING',   '2026-07-02 08:00:00+05:30', NULL),
(26,  6, 'AB', 'POSITIVE',  1, 'ROUTINE',   'PENDING',   '2026-07-02 09:30:00+05:30', NULL),
(27,  7, 'O',  'NEGATIVE',  2, 'URGENT',    'PENDING',   '2026-07-03 10:00:00+05:30', NULL),
(28,  8, 'B',  'NEGATIVE',  3, 'EMERGENCY', 'PENDING',   '2026-07-03 07:30:00+05:30', NULL),
(29,  9, 'A',  'NEGATIVE',  1, 'ROUTINE',   'PENDING',   '2026-07-04 14:00:00+05:30', NULL),
(30, 10, 'AB', 'NEGATIVE',  2, 'URGENT',    'PENDING',   '2026-07-04 09:00:00+05:30', NULL),
(31,  1, 'O',  'POSITIVE',  5, 'EMERGENCY', 'PENDING',   '2026-07-05 08:00:00+05:30', NULL),
(32,  2, 'B',  'POSITIVE',  3, 'ROUTINE',   'PENDING',   '2026-07-05 10:30:00+05:30', NULL),
(33,  3, 'A',  'POSITIVE',  2, 'URGENT',    'PENDING',   '2026-07-06 11:00:00+05:30', NULL),
(34,  4, 'O',  'POSITIVE',  4, 'EMERGENCY', 'PENDING',   '2026-07-06 07:00:00+05:30', NULL),
(35,  5, 'O',  'NEGATIVE',  3, 'ROUTINE',   'PENDING',   '2026-07-07 14:00:00+05:30', NULL),

       
(36,  6, 'O',  'POSITIVE',  2, 'ROUTINE',   'CANCELLED', '2026-06-25 10:00:00+05:30', NULL),
(37,  7, 'B',  'POSITIVE',  3, 'ROUTINE',   'CANCELLED', '2026-06-26 11:00:00+05:30', NULL),
(38,  8, 'A',  'POSITIVE',  1, 'URGENT',    'CANCELLED', '2026-06-27 09:30:00+05:30', NULL),
(39,  9, 'O',  'NEGATIVE',  4, 'ROUTINE',   'CANCELLED', '2026-06-28 14:00:00+05:30', NULL),
(40, 10, 'AB', 'POSITIVE',  2, 'ROUTINE',   'CANCELLED', '2026-06-29 10:00:00+05:30', NULL);




INSERT INTO unit_reservations (reservation_id, unit_id, request_id, reserved_at)
VALUES
       
( 1, 111,  1, '2026-05-10 08:30:00+05:30'),
( 2, 112,  1, '2026-05-10 08:30:01+05:30'),
( 3, 113,  1, '2026-05-10 08:30:02+05:30'),
       
( 4, 114,  2, '2026-05-12 09:15:00+05:30'),
( 5, 115,  2, '2026-05-12 09:15:01+05:30'),
( 6, 116,  2, '2026-05-12 09:15:02+05:30'),
       
( 7, 117,  3, '2026-05-14 10:10:00+05:30'),
( 8, 118,  3, '2026-05-14 10:10:01+05:30'),
( 9, 119,  3, '2026-05-14 10:10:02+05:30'),
(10, 120,  3, '2026-05-14 10:10:03+05:30'),
       
(11, 121,  4, '2026-05-16 11:10:00+05:30'),
(12, 122,  4, '2026-05-16 11:10:01+05:30'),
(13, 123,  4, '2026-05-16 11:10:02+05:30'),
       
(14, 124,  5, '2026-05-18 14:15:00+05:30'),
(15, 125,  5, '2026-05-18 14:15:01+05:30'),
       
(16, 126,  6, '2026-05-20 09:45:00+05:30'),
(17, 127,  6, '2026-05-20 09:45:01+05:30'),
(18, 128,  6, '2026-05-20 09:45:02+05:30'),
       
(19, 129,  7, '2026-05-22 07:10:00+05:30'),
(20, 130,  7, '2026-05-22 07:10:01+05:30'),

       
(21,  51,  8, '2026-06-10 10:15:00+05:30'),
(22,  52,  8, '2026-06-10 10:15:01+05:30'),
(23,  53,  8, '2026-06-10 10:15:02+05:30'),
(24,  54,  8, '2026-06-10 10:15:03+05:30'),
(25,  55,  8, '2026-06-10 10:15:04+05:30'),
       
(26,  56,  9, '2026-06-11 11:10:00+05:30'),
(27,  57,  9, '2026-06-11 11:10:01+05:30'),
(28,  58,  9, '2026-06-11 11:10:02+05:30'),
(29,  59,  9, '2026-06-11 11:10:03+05:30'),
(30,  60,  9, '2026-06-11 11:10:04+05:30'),
       
(31,  61, 10, '2026-06-12 09:05:00+05:30'),
(32,  62, 10, '2026-06-12 09:05:01+05:30'),
(33,  63, 10, '2026-06-12 09:05:02+05:30'),
(34,  64, 10, '2026-06-12 09:05:03+05:30'),
(35,  65, 10, '2026-06-12 09:05:04+05:30'),
       
(36,  66, 11, '2026-06-13 08:40:00+05:30'),
(37,  67, 11, '2026-06-13 08:40:01+05:30'),
(38,  68, 11, '2026-06-13 08:40:02+05:30'),
(39,  69, 11, '2026-06-13 08:40:03+05:30'),
(40,  70, 11, '2026-06-13 08:40:04+05:30'),
       
(41,  71, 12, '2026-06-14 10:10:00+05:30'),
(42,  72, 12, '2026-06-14 10:10:01+05:30'),
(43,  73, 12, '2026-06-14 10:10:02+05:30'),
(44,  74, 12, '2026-06-14 10:10:03+05:30'),
       
(45,  75, 13, '2026-06-15 11:35:00+05:30'),
(46,  76, 13, '2026-06-15 11:35:01+05:30'),
(47,  77, 13, '2026-06-15 11:35:02+05:30'),
(48,  78, 13, '2026-06-15 11:35:03+05:30'),
       
(49,  79, 14, '2026-06-16 09:10:00+05:30'),
(50,  80, 14, '2026-06-16 09:10:01+05:30'),
(51,  81, 14, '2026-06-16 09:10:02+05:30'),
(52,  82, 14, '2026-06-16 09:10:03+05:30'),
       
(53,  83, 15, '2026-06-17 10:40:00+05:30'),
(54,  84, 15, '2026-06-17 10:40:01+05:30'),
(55,  85, 15, '2026-06-17 10:40:02+05:30'),
(56,  86, 15, '2026-06-17 10:40:03+05:30'),
       
(57,  87, 16, '2026-06-18 08:05:00+05:30'),
(58,  88, 16, '2026-06-18 08:05:01+05:30'),
(59,  89, 16, '2026-06-18 08:05:02+05:30'),
(60,  90, 16, '2026-06-18 08:05:03+05:30'),
       
(61,  91, 17, '2026-06-19 14:10:00+05:30'),
(62,  92, 17, '2026-06-19 14:10:01+05:30'),
(63,  93, 17, '2026-06-19 14:10:02+05:30'),
(64,  94, 17, '2026-06-19 14:10:03+05:30'),

       
(65,  95, 18, '2026-06-20 07:45:00+05:30'),
(66,  96, 18, '2026-06-20 07:45:01+05:30'),
(67,  97, 18, '2026-06-20 07:45:02+05:30'),
(68,  98, 18, '2026-06-20 07:45:03+05:30'),
       
(69,  99, 19, '2026-06-21 09:15:00+05:30'),
(70, 100, 19, '2026-06-21 09:15:01+05:30'),
       
(71, 101, 20, '2026-06-22 08:20:00+05:30'),
(72, 102, 20, '2026-06-22 08:20:01+05:30'),
(73, 103, 20, '2026-06-22 08:20:02+05:30'),
(74, 104, 20, '2026-06-22 08:20:03+05:30'),
(75, 105, 20, '2026-06-22 08:20:04+05:30'),
       
(76, 106, 21, '2026-06-23 10:15:00+05:30'),
(77, 107, 21, '2026-06-23 10:15:01+05:30'),
(78, 108, 21, '2026-06-23 10:15:02+05:30'),
       
(79, 109, 22, '2026-06-24 07:20:00+05:30'),
(80, 110, 22, '2026-06-24 07:20:01+05:30');



SELECT setval('donors_donor_id_seq',             (SELECT MAX(donor_id)      FROM donors));
SELECT setval('blood_units_unit_id_seq',         (SELECT MAX(unit_id)       FROM blood_units));
SELECT setval('hospitals_hospital_id_seq',       (SELECT MAX(hospital_id)   FROM hospitals));
SELECT setval('blood_requests_request_id_seq',   (SELECT MAX(request_id)    FROM blood_requests));
SELECT setval('unit_reservations_reservation_id_seq', (SELECT MAX(reservation_id) FROM unit_reservations));




DO $$
DECLARE
    v_donors   INT;
    v_units    INT;
    v_hosp     INT;
    v_req      INT;
    v_res      INT;
BEGIN
    SELECT COUNT(*) INTO v_donors FROM donors;
    SELECT COUNT(*) INTO v_units  FROM blood_units;
    SELECT COUNT(*) INTO v_hosp   FROM hospitals;
    SELECT COUNT(*) INTO v_req    FROM blood_requests;
    SELECT COUNT(*) INTO v_res    FROM unit_reservations;

    RAISE NOTICE '════════════════════════════════════════';
    RAISE NOTICE '  SEED DATA LOADED SUCCESSFULLY';
    RAISE NOTICE '════════════════════════════════════════';
    RAISE NOTICE '  Donors:       %', v_donors;
    RAISE NOTICE '  Blood Units:  %', v_units;
    RAISE NOTICE '  Hospitals:    %', v_hosp;
    RAISE NOTICE '  Requests:     %', v_req;
    RAISE NOTICE '  Reservations: %', v_res;
    RAISE NOTICE '════════════════════════════════════════';
END $$;

COMMIT;

