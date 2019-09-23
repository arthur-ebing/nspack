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
         'Product Setup Templates', '/list/product_setup_templates', 1);

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
         'Active Product Setups', '/list/product_setups/with_params?key=active&product_setups.active=true', 3);

-- LIST menu item
-- PROGRAM FUNCTION Product_setups in Production
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Product_setups'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Production')),
         'Product Setups in Production', '/production/product_setups/product_setups/list_product_setups_in_production', 4);

-- SEARCH menu item
-- PROGRAM FUNCTION Search Product_setups
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Product_setups'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Production')),
         'Search Product Setups', '/search/product_setups', 5);
