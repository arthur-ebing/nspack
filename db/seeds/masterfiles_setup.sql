
INSERT INTO functional_areas (functional_area_name)
VALUES ('Masterfiles');

-- GENERAL

INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('General', 1, (SELECT id FROM functional_areas WHERE functional_area_name = 'Masterfiles'));

INSERT INTO programs_webapps(program_id, webapp)
VALUES ((SELECT id FROM programs WHERE program_name = 'General' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Masterfiles')), 'Nspack');

INSERT INTO program_functions (program_id, program_function_name, group_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'General'
                                   AND functional_area_id = (SELECT id FROM functional_areas
                                                             WHERE functional_area_name = 'Masterfiles')),
        'UOM Types', 'Units of Measure', '/list/uom_types', 2);

INSERT INTO program_functions (program_id, program_function_name, group_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'General'
                                   AND functional_area_id = (SELECT id FROM functional_areas
                                                             WHERE functional_area_name = 'Masterfiles')),
        'UOMs', 'Units of Measure', '/list/uoms', 2);

-- PARTIES
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Parties', 1, (SELECT id FROM functional_areas WHERE functional_area_name = 'Masterfiles'));

INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs WHERE program_name = 'Parties' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Masterfiles')), 'Nspack');

-- Grouped in Contact Details
INSERT INTO program_functions (program_id, program_function_name, group_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Parties'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Addresses', 'Contact Details', '/list/addresses', 2);

INSERT INTO program_functions (program_id, program_function_name, group_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Parties'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Contact methods', 'Contact Details', '/list/contact_methods', 2);

-- Not Grouped
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Parties'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Organizations', '/list/organizations', 2);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Parties'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'People', '/list/people', 2);


-- FRUIT
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Fruit', 2, (SELECT id FROM functional_areas WHERE functional_area_name = 'Masterfiles'));

INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs WHERE program_name = 'Fruit' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Masterfiles')), 'Nspack');

-- Grouped in Commodities
INSERT INTO program_functions (program_id, program_function_name, group_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Fruit'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Groups', 'Commodities', '/list/commodity_groups', 1);

INSERT INTO program_functions (program_id, program_function_name, group_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Fruit'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Commodities', 'Commodities', '/list/commodities', 2);

-- Grouped in Cultivars
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Fruit'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Groups', '/list/cultivar_groups', 2, 'Cultivars');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Fruit'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Cultivars', '/list/cultivars', 2, 'Cultivars');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Fruit'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Marketing varieties', '/list/marketing_varieties', 2, 'Cultivars');

-- Sizes
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Fruit'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Std Fruit Size Counts', '/list/std_fruit_size_counts', 3, 'Sizes');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Fruit'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Size References', '/list/fruit_size_references', 4, 'Sizes');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Fruit'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Size Conversions', '/search/fruit_actual_counts_for_packs', 5, 'Sizes');

-- Not Grouped
-- RMT Classes
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Fruit'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'RMT Classes', '/list/rmt_classes', 2);

-- TARGET MARKETS
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Target Markets', 3, (SELECT id FROM functional_areas WHERE functional_area_name = 'Masterfiles'));

INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs WHERE program_name = 'Target Markets' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Masterfiles')), 'Nspack');

-- Grouped in Target Markets
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Target Markets'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Types', '/list/target_market_group_types', 2, 'Target markets');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Target Markets'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Groups', '/list/target_market_groups', 2, 'Target markets');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Target Markets'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Target markets', '/list/target_markets', 2, 'Target markets');

--Grouped in Destination
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Target Markets'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Regions', '/list/destination_regions', 2, 'Destination');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Target Markets'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Countries', '/list/destination_countries', 2, 'Destination');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Target Markets'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Cities', '/list/destination_cities', 2, 'Destination');


-- LOCATIONS

--INSERT INTO functional_areas (functional_area_name) VALUES ('Masterfiles');

INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Locations', 1, (SELECT id FROM functional_areas
                                              WHERE functional_area_name = 'Masterfiles'));

INSERT INTO programs_webapps(program_id, webapp) VALUES (
      (SELECT id FROM programs
       WHERE program_name = 'Locations'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
       'Nspack');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Locations'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Locations', '/list/locations', 2);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Locations'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Search Locations', '/search/locations', 2);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Locations'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Assignments', '/list/location_assignments', 2);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Locations'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Types', '/list/location_types', 2);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Locations'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Storage Types', '/list/location_storage_types', 2);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Locations'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Storage Definitions', '/list/location_storage_definitions', 2);

INSERT INTO location_types (location_type_code, short_code) VALUES ('RECEIVING BAY', 'RB');


-- CONFIG / LABEL TEMPLATES

-- PROGRAM: Config
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Config', 1,
        (SELECT id FROM functional_areas WHERE functional_area_name = 'Masterfiles'));

-- LINK program to webapp
INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs
                   WHERE program_name = 'Config'
                     AND functional_area_id = (SELECT id
                                               FROM functional_areas
                                               WHERE functional_area_name = 'Masterfiles')),
                                               'Nspack');


-- PROGRAM FUNCTION Label_templates
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence,
                               group_name, restricted_user_access, show_in_iframe)
VALUES ((SELECT id FROM programs WHERE program_name = 'Config'
          AND functional_area_id = (SELECT id FROM functional_areas
                                    WHERE functional_area_name = 'Masterfiles')),
        'Label_templates',
        '/list/label_templates',
        2,
        NULL,
        false,
        false);

-- PROGRAM calendar
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Calendar', 1, (SELECT id FROM functional_areas
                                              WHERE functional_area_name = 'Masterfiles'));

INSERT INTO programs_webapps(program_id, webapp) VALUES (
      (SELECT id FROM programs
       WHERE program_name = 'Calendar'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
       'Nspack');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Calendar'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Season_groups', '/list/season_groups', 1);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Calendar'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Seasons', '/list/seasons', 2);

-- PROGRAM raw_materials
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Raw Materials', 1, (SELECT id FROM functional_areas
                                              WHERE functional_area_name = 'Masterfiles'));

INSERT INTO programs_webapps(program_id, webapp) VALUES (
      (SELECT id FROM programs
       WHERE program_name = 'Raw Materials'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
       'Nspack');

-- LIST menu item
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Raw Materials'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Rmt_delivery_destinations', '/list/rmt_delivery_destinations', 2);



-- PROGRAM: Farms
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Farms', 1,
        (SELECT id FROM functional_areas WHERE functional_area_name = 'Masterfiles'));

-- LINK program to webapp
INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs
                   WHERE program_name = 'Farms'
                     AND functional_area_id = (SELECT id
                                               FROM functional_areas
                                               WHERE functional_area_name = 'Masterfiles')),
                                               'Nspack');


-- PROGRAM FUNCTION Production_regions
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence,
                               group_name, restricted_user_access, show_in_iframe)
VALUES ((SELECT id FROM programs WHERE program_name = 'Farms'
          AND functional_area_id = (SELECT id FROM functional_areas
                                    WHERE functional_area_name = 'Masterfiles')),
        'Production_regions',
        '/list/production_regions',
        1,
        NULL,
        false,
        false);

-- Farms
-- LIST menu item
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Farms'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Pucs', '/list/pucs', 2);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Farms'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Farm_groups', '/list/farm_groups', 3);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Farms'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Farms', '/list/farms', 4);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Farms'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Orchards', '/list/orchard_details', 5);

INSERT INTO roles (name)
	VALUES ('FARM_OWNER');

-- Grades
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Fruit'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Grades', '/list/grades', 3);

-- Grouped in Treatments
INSERT INTO program_functions (program_id, program_function_name, group_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Fruit'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Groups', 'Treatments', '/list/treatment_types', 4);

INSERT INTO program_functions (program_id, program_function_name, group_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Fruit'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Treatments', 'Treatments', '/list/treatments', 5);

-- Inventory Codes
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Fruit'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Inventory Codes', '/list/inventory_codes', 6);

-- Marketing
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Marketing', 1, (SELECT id FROM functional_areas
                                              WHERE functional_area_name = 'Masterfiles'));

INSERT INTO programs_webapps(program_id, webapp) VALUES (
      (SELECT id FROM programs
       WHERE program_name = 'Marketing'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
       'Nspack');

-- LIST menu item
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Marketing'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Marks', '/list/marks', 2);

-- Packaging
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Packaging', 1, (SELECT id FROM functional_areas
                                              WHERE functional_area_name = 'Masterfiles'));

INSERT INTO programs_webapps(program_id, webapp) VALUES (
      (SELECT id FROM programs
       WHERE program_name = 'Packaging'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
       'Nspack');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Packaging'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Pallet Bases', '/list/pallet_bases', 1);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Packaging'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Pallet Stack Types', '/list/pallet_stack_types', 2);


-- Grouped in Pack codes
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Packaging'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Basic', '/list/basic_pack_codes', 4, 'Pack codes');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Packaging'
                                       AND functional_area_id = (SELECT id FROM functional_areas
WHERE functional_area_name = 'Masterfiles')),
        'Standard', '/list/standard_pack_codes', 4, 'Pack codes');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Packaging'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Pallet Formats', '/list/pallet_formats', 3);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Packaging'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Cartons Per Pallet', '/list/cartons_per_pallet', 5);

-- SEARCH menu item
-- PROGRAM FUNCTION Search Cartons_per_pallet
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Packaging'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Search Cartons Per Pallet', '/search/cartons_per_pallet', 6);


-- Grouped in Bill of Materials
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Packaging'
         AND functional_area_id = (SELECT id FROM functional_areas
         WHERE functional_area_name = 'Masterfiles')),
        'PM Types', '/list/pm_types', 7, 'Bill of Materials');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Packaging'
         AND functional_area_id = (SELECT id FROM functional_areas
         WHERE functional_area_name = 'Masterfiles')),
        'PM Subtypes', '/list/pm_subtypes', 8, 'Bill of Materials');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Packaging'
         AND functional_area_id = (SELECT id FROM functional_areas
         WHERE functional_area_name = 'Masterfiles')),
        'PM Products', '/list/pm_products', 9, 'Bill of Materials');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Packaging'
         AND functional_area_id = (SELECT id FROM functional_areas
         WHERE functional_area_name = 'Masterfiles')),
        'PM BOMs', '/list/pm_boms', 10, 'Bill of Materials');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence, group_name)
VALUES ((SELECT id FROM programs WHERE program_name = 'Packaging'
         AND functional_area_id = (SELECT id FROM functional_areas
         WHERE functional_area_name = 'Masterfiles')),
         'Search PM BOMs Products', '/search/pm_boms_products', 11, 'Bill of Materials');

-- Marketing Varieties
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Marketing'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Customer Varieties', '/list/customer_varieties', 3);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Marketing'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Search Customer Variety Marketing Varieties', '/search/customer_variety_varieties', 4);

-- LIST menu item
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Farms'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Rmt_container_types', '/list/rmt_container_types', 2);

-- LIST menu item
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Farms'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Masterfiles')),
         'Rmt_container_material_types', '/list/rmt_container_material_types', 2);



-- NEW functional area
INSERT INTO functional_areas (functional_area_name) VALUES ('Raw Materials');

INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Deliveries', 1, (SELECT id FROM functional_areas
                                              WHERE functional_area_name = 'Raw Materials'));

INSERT INTO programs_webapps(program_id, webapp) VALUES (
      (SELECT id FROM programs
       WHERE program_name = 'Deliveries'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Raw Materials')),
       'Nspack');

-- NEW menu item
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Deliveries'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Raw Materials')),
         'New Delivery', '/raw_materials/deliveries/rmt_deliveries/new', 1);


-- LIST menu item
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Deliveries'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Raw Materials')),
         'Deliveries', '/list/rmt_deliveries', 2);

-- SEARCH menu item

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Deliveries'
         AND functional_area_id = (SELECT id FROM functional_areas
                                   WHERE functional_area_name = 'Raw Materials')),
         'Search Deliveries', '/search/rmt_deliveries', 2);
