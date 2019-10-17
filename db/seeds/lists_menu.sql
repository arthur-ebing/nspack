-- FUNCTIONAL AREA Lists
INSERT INTO functional_areas (functional_area_name, rmd_menu)
VALUES ('Lists', false);

-- PROGRAM: Bins
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Bins', 1,
        (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists'));

-- LINK program to webapp
INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs
                   WHERE program_name = 'Bins'
                     AND functional_area_id = (SELECT id
                                               FROM functional_areas
                                               WHERE functional_area_name = 'Lists')),
                                               'Nspack');

-- PROGRAM FUNCTIONS
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Bins'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'List', '/list/rmt_bins', 1);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Bins'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Search', '/search/rmt_bins', 2);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Bins'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Tipped', '/list/rmt_bins/with_params?key=tipped&tipped=true', 3);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Bins'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'In Stock', '/list/rmt_bins/with_params?key=tipped&tipped=false', 4);

-- PROGRAM: Cartons
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Cartons', 2,
        (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists'));

-- LINK program to webapp
INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs
                   WHERE program_name = 'Cartons'
                     AND functional_area_id = (SELECT id
                                               FROM functional_areas
                                               WHERE functional_area_name = 'Lists')),
                                               'Nspack');

-- PROGRAM FUNCTIONS
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Cartons'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'List', '/list/cartons', 1);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Cartons'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Search', '/search/cartons', 2);

-- PROGRAM: Pallets
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Pallets', 3,
        (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists'));

-- LINK program to webapp
INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs
                   WHERE program_name = 'Pallets'
                     AND functional_area_id = (SELECT id
                                               FROM functional_areas
                                               WHERE functional_area_name = 'Lists')),
                                               'Nspack');

-- PROGRAM FUNCTIONS
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallets'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'List', '/list/all_pallets', 1);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallets'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Search', '/search/pallets', 2);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallets'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Daily Pack', '/list/pallets/with_params?key=daily_pack&in_stock=false', 3);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallets'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Stock', '/list/pallets/with_params?key=in_stock&in_stock=true', 4);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallets'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Allocated Stock', '/list/pallets/with_params?key=allocated_stock&in_stock=true&allocated=true', 5);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallets'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Unallocated Stock', '/list/pallets/with_params?key=unallocated_stock&in_stock=true&allocated=false', 6);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallets'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Shipped', '/list/pallets/with_params?key=shipped&shipped=true', 7);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallets'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Scrapped', '/list/pallets/with_params?key=scrapped&scrapped=true', 8);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallets'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Failed Inspections', '/list/pallets/with_params?key=failed_inspections&inspected=true&govt_inspection_passed=false', 9);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallets'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Failed Verifications', '/list/pallets/with_params?key=failed_verifications&pallet_verification_failed=true', 10);

-- PROGRAM: Pallet Sequences
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Pallet Sequences', 4,
        (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists'));

-- LINK program to webapp
INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs
                   WHERE program_name = 'Pallet Sequences'
                     AND functional_area_id = (SELECT id
                                               FROM functional_areas
                                               WHERE functional_area_name = 'Lists')),
                                               'Nspack');
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallet Sequences'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'List', '/list/all_pallets', 1);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallet Sequences'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Search', '/search/pallets', 2);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallet Sequences'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Daily Pack', '/list/pallet_sequences/with_params?key=daily_pack&in_stock=false', 3);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallet Sequences'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Stock', '/list/pallet_sequences/with_params?key=in_stock&in_stock=true', 4);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallet Sequences'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Allocated Stock', '/list/pallet_sequences/with_params?key=allocated_stock&in_stock=true&allocated=true', 5);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallet Sequences'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Unallocated Stock', '/list/pallet_sequences/with_params?key=unallocated_stock&in_stock=true&allocated=false', 6);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallet Sequences'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Shipped', '/list/pallet_sequences/with_params?key=shipped&shipped=true', 7);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallet Sequences'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Scrapped', '/list/pallet_sequences/with_params?key=scrapped&scrapped=true', 8);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallet Sequences'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Failed Inspections', '/list/pallet_sequences/with_params?key=failed_inspections&inspected=true&govt_inspection_passed=false', 9);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Pallet Sequences'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Lists')),
        'Failed Verifications', '/list/pallet_sequences/with_params?key=failed_verifications&verified=true&verification_passed=false&in_stock=true', 10);
