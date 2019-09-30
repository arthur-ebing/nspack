-- CONTACT METHOD TYPES
INSERT INTO public.contact_method_types(contact_method_type) VALUES ('Tel');
INSERT INTO public.contact_method_types(contact_method_type) VALUES ('Fax');
INSERT INTO public.contact_method_types(contact_method_type) VALUES ('Cell');
INSERT INTO public.contact_method_types(contact_method_type) VALUES ('Email');

-- ADDRESS TYPES
INSERT INTO public.address_types(address_type) VALUES ('Delivery Address');

-- ROLES
INSERT INTO roles (name) VALUES ('IMPLEMENTATION_OWNER');
-- INSERT INTO roles (name) VALUES ('TRANSPORTER');
INSERT INTO roles (name) VALUES ('OTHER');
-- INSERT INTO roles (name) VALUES ('CUSTOMER');
-- INSERT INTO roles (name) VALUES ('SUPPLIER');
INSERT INTO roles (name) VALUES ('MARKETER');


-- UNITS OF MEASURE TYPE
INSERT INTO uom_types (code) VALUES ('INVENTORY');

-- PM TYPE
INSERT INTO pm_types (pm_type_code, description) VALUES ('BIN', 'BIN');
INSERT INTO pm_types (pm_type_code, description) VALUES ('CARTON', 'CARTON');

-- VOYAGE_TYPES
INSERT INTO voyage_types (voyage_type_code, description) VALUES('ROAD', 'Trucks');
INSERT INTO voyage_types (voyage_type_code, description) VALUES('AIR', 'Air');
INSERT INTO voyage_types (voyage_type_code, description) VALUES('SEA', 'Sea');
INSERT INTO voyage_types (voyage_type_code, description) VALUES('RAIL', 'Rail');

-- VESSEL_TYPES
INSERT INTO vessel_types (voyage_type_id, vessel_type_code, description) VALUES((SELECT id FROM voyage_types WHERE voyage_type_code = 'ROAD'), 'TRUCK', 'Truck');
INSERT INTO vessel_types (voyage_type_id, vessel_type_code, description) VALUES((SELECT id FROM voyage_types WHERE voyage_type_code = 'SEA'), 'SHIP', 'Ship');
INSERT INTO vessel_types (voyage_type_id, vessel_type_code, description) VALUES((SELECT id FROM voyage_types WHERE voyage_type_code = 'RAIL'), 'TRAIN', 'Train');
INSERT INTO vessel_types (voyage_type_id, vessel_type_code, description) VALUES((SELECT id FROM voyage_types WHERE voyage_type_code = 'AIR'), 'AIRCRAFT', 'Aircraft');

-- PORT_TYPES
INSERT INTO port_types (port_type_code, description) VALUES('POL', 'Port of Loading');
INSERT INTO port_types (port_type_code, description) VALUES('POD', 'Port of Dispatch');
INSERT INTO port_types (port_type_code, description) VALUES('TRANSSHIP', 'Transfer Shipment');
