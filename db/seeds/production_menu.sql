-- FUNCTIONAL AREA Production
INSERT INTO functional_areas (functional_area_name, rmd_menu)
VALUES ('Production', false);


-- PROGRAM: Resources
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Resources', 1,
        (SELECT id FROM functional_areas WHERE functional_area_name = 'Production'));

-- LINK program to webapp
INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs
                   WHERE program_name = 'Resources'
                     AND functional_area_id = (SELECT id
                                               FROM functional_areas
                                               WHERE functional_area_name = 'Production')),
                                               'Nspack');


-- PROGRAM FUNCTION Plant Resources
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence,
                               group_name, restricted_user_access, show_in_iframe)
VALUES ((SELECT id FROM programs WHERE program_name = 'Resources'
          AND functional_area_id = (SELECT id FROM functional_areas
                                    WHERE functional_area_name = 'Production')),
        'Plant Resources',
        '/list/plant_resources',
        2,
        NULL,
        false,
        false);


-- PROGRAM FUNCTION Plant resource types
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence,
                               group_name, restricted_user_access, show_in_iframe)
VALUES ((SELECT id FROM programs WHERE program_name = 'Resources'
          AND functional_area_id = (SELECT id FROM functional_areas
                                    WHERE functional_area_name = 'Production')),
        'Plant resource types',
        '/list/plant_resource_types',
        2,
        'Resource Types',
        false,
        false);


-- PROGRAM FUNCTION System_resource_types
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence,
                               group_name, restricted_user_access, show_in_iframe)
VALUES ((SELECT id FROM programs WHERE program_name = 'Resources'
          AND functional_area_id = (SELECT id FROM functional_areas
                                    WHERE functional_area_name = 'Production')),
        'System_resource_types',
        '/list/system_resource_types',
        3,
        'Resource Types',
        false,
        false);

-- PROGRAM: Product Setup
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Product_setups', 1, (SELECT id FROM functional_areas
                                              WHERE functional_area_name = 'Production'));

-- LINK program to webapp
INSERT INTO programs_webapps(program_id, webapp) VALUES (
      (SELECT id FROM programs
       WHERE program_name = 'Product_setups'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Production')),
       'Nspack');

-- LIST menu item
-- PROGRAM FUNCTION Product_setup_templates
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Product_setups'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Production')),
         'Product Setup Templates', '/list/product_setup_templates/with_params?key=active&product_setup_templates.active=true', 1);

-- SEARCH menu item
-- PROGRAM FUNCTION Search Product_setup_templates
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Product_setups'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Production')),
         'Search Product Setup Templates', '/search/product_setup_templates', 2);


-- LIST menu item
-- PROGRAM FUNCTION Active Product_setups
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Product_setups'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Production')),
         'Active Product Setups', '/list/product_setup_details/with_params?key=active&product_setups.active=true', 3);

-- LIST menu item
-- PROGRAM FUNCTION Product_setups in Production
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Product_setups'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Production')),
         'Product Setups in Production', '/list/product_setup_details/with_params?key=in_production&in_production=true', 4);

-- SEARCH menu item
-- PROGRAM FUNCTION Search Product_setups
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Product_setups'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Production')),
         'Search Product Setups', '/search/product_setups', 5);

-- PROGRAM: Runs
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Runs', 1, (SELECT id FROM functional_areas
                                              WHERE functional_area_name = 'Production'));

-- LINK program to webapp
INSERT INTO programs_webapps(program_id, webapp) VALUES (
      (SELECT id FROM programs
       WHERE program_name = 'Runs'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Production')),
       'Nspack');

-- LIST menu item
-- PROGRAM FUNCTION Production_runs
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Runs'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Production')),
         'List Production runs', '/list/production_runs', 2);

-- SEARCH menu item
-- PROGRAM FUNCTION Search Production_runs

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Runs'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Production')),
         'Search Production runs', '/search/production_runs', 2);

-- Grouped in List Objects
INSERT INTO program_functions (program_id, program_function_name, group_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Runs'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Production')),
        'Cartons', 'List Objects', '/list/cartons', 3);

--INSERT INTO program_functions (program_id, program_function_name, group_name, url, program_function_sequence)
--VALUES ((SELECT id FROM programs WHERE program_name = 'Runs'
--         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Production')),
--        'Bins', 'List Objects', '/list/bins', 4);
--
--INSERT INTO program_functions (program_id, program_function_name, group_name, url, program_function_sequence)
--VALUES ((SELECT id FROM programs WHERE program_name = 'Runs'
--         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Production')),
--        'Pallets', 'List Objects', '/list/pallets', 5);

-- Grouped in Search Objects
INSERT INTO program_functions (program_id, program_function_name, group_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Runs'
         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Production')),
        'Cartons', 'Search Objects', '/search/cartons', 6);

--INSERT INTO program_functions (program_id, program_function_name, group_name, url, program_function_sequence)
--VALUES ((SELECT id FROM programs WHERE program_name = 'Runs'
--         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Production')),
--        'Bins', 'Search Objects', '/search/bins', 7);
--
--INSERT INTO program_functions (program_id, program_function_name, group_name, url, program_function_sequence)
--VALUES ((SELECT id FROM programs WHERE program_name = 'Runs'
--         AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Production')),
--        'Pallets', 'Search Objects', '/search/pallets', 8);