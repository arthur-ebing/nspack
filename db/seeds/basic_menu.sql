INSERT INTO functional_areas (functional_area_name)
VALUES ('security');

INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('menu', 1, (SELECT id FROM functional_areas WHERE functional_area_name = 'security'));

INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs WHERE program_name = 'menu' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'security')), 'Nspack');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'menu' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'security')), 'list menu definitions', '/list/menu_definitions', 1);


INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'menu' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'security')), 'security groups', '/list/security_groups', 1);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'menu' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'security')), 'security permissions', '/list/security_permissions', 1);



INSERT INTO functional_areas (functional_area_name)
VALUES ('Development');

INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Generators', 1, (SELECT id FROM functional_areas WHERE functional_area_name = 'Development'));

INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs WHERE program_name = 'Generators' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Development')), 'Nspack');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Generators' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Development')), 'New Scaffold', '/development/generators/scaffolds/new', 1);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Generators' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Development')), 'Documentation', '/developer_documentation/start', 2);

INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Logging', 3, (SELECT id FROM functional_areas WHERE functional_area_name = 'Development'));

INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs WHERE program_name = 'Logging' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Development')), 'Nspack');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Logging' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Development')), 'Search logged actions', '/search/logged_actions', 1);

INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Masterfiles', 2, (SELECT id FROM functional_areas WHERE functional_area_name = 'Development'));

INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs WHERE program_name = 'Masterfiles' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Development')), 'Nspack');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Masterfiles' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Development')), 'Users', '/list/users', 1);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Masterfiles'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Development')),
         'User_email_groups', '/list/user_email_groups', 2);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Masterfiles' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Development')), 'Contact Method Types', '/list/contact_method_types', 1);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Masterfiles' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Development')), 'Address Types', '/list/address_types', 1);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Masterfiles' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Development')), 'Party Roles', '/list/roles', 1);

-- Registered Mobile Devices menu:
INSERT INTO functional_areas (functional_area_name, rmd_menu)
VALUES ('RMD', true);

-- PROGRAM: Home
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Home', 1,
        (SELECT id FROM functional_areas WHERE functional_area_name = 'RMD'));

-- LINK program to webapp
INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs
                   WHERE program_name = 'Home'
                     AND functional_area_id = (SELECT id
                                               FROM functional_areas
                                               WHERE functional_area_name = 'RMD')),
                                               'Nspack');


-- PROGRAM FUNCTION Menu
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence,
                               group_name, restricted_user_access, show_in_iframe)
VALUES ((SELECT id FROM programs WHERE program_name = 'Home'
          AND functional_area_id = (SELECT id FROM functional_areas
                                    WHERE functional_area_name = 'RMD')),
        'Menu',
        '/rmd/home',
        1,
        NULL,
        false,
        false);


-- PROGRAM: Utilities
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Utilities', 1,
        (SELECT id FROM functional_areas WHERE functional_area_name = 'RMD'));

-- LINK program to webapp
INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs
                   WHERE program_name = 'Utilities'
                     AND functional_area_id = (SELECT id
                                               FROM functional_areas
                                               WHERE functional_area_name = 'RMD')),
                                               'Nspack');

-- PROGRAM FUNCTION Check Barcodes
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence,
                               group_name, restricted_user_access, show_in_iframe)
VALUES ((SELECT id FROM programs WHERE program_name = 'Utilities'
          AND functional_area_id = (SELECT id FROM functional_areas
                                    WHERE functional_area_name = 'RMD')),
        'Check Barcodes',
        '/rmd/utilities/check_barcode',
        1,
        NULL,
        false,
        false);

-- PROGRAM FUNCTION Check Barcodes
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence,
                               group_name, restricted_user_access, show_in_iframe)
VALUES ((SELECT id FROM programs WHERE program_name = 'Utilities'
          AND functional_area_id = (SELECT id FROM functional_areas
                                    WHERE functional_area_name = 'RMD')),
        'Toggle Camera Scan',
        '/rmd/utilities/toggle_camera',
        2,
        NULL,
        false,
        false);

