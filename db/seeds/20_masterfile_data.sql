-- ADDRESS TYPES
INSERT INTO public.address_types(address_type) VALUES ('Delivery Address');

-- CONTACT METHOD TYPES
INSERT INTO public.contact_method_types(contact_method_type) VALUES ('Tel');
INSERT INTO public.contact_method_types(contact_method_type) VALUES ('Fax');
INSERT INTO public.contact_method_types(contact_method_type) VALUES ('Cell');
INSERT INTO public.contact_method_types(contact_method_type) VALUES ('Email');

-- PM TYPE
INSERT INTO pm_types (pm_type_code, description) VALUES ('BIN', 'BIN');
INSERT INTO pm_types (pm_type_code, description) VALUES ('CARTON', 'CARTON');

-- PORT_TYPES
INSERT INTO port_types (port_type_code, description) VALUES('POL', 'Port of Loading');
INSERT INTO port_types (port_type_code, description) VALUES('POD', 'Port of Dispatch');
INSERT INTO port_types (port_type_code, description) VALUES('TRANSSHIP', 'Transfer Shipment');

-- ROLES
INSERT INTO roles (name) VALUES ('IMPLEMENTATION_OWNER');
INSERT INTO roles (name) VALUES ('TRANSPORTER');
INSERT INTO roles (name) VALUES ('OTHER');
INSERT INTO roles (name) VALUES ('CUSTOMER');
INSERT INTO roles (name) VALUES ('SUPPLIER');
INSERT INTO roles (name) VALUES ('MARKETER');
INSERT INTO roles (name) VALUES ('SHIPPING_LINE');
INSERT INTO roles (name) VALUES ('SHIPPER');
INSERT INTO roles (name) VALUES ('FINAL_RECEIVER');
INSERT INTO roles (name) VALUES ('EXPORTER');
INSERT INTO roles (name) VALUES ('BILLING_CLIENT');
INSERT INTO roles (name) VALUES ('CONSIGNEE');
INSERT INTO roles (name) VALUES ('HAULIER');
INSERT INTO roles (name) VALUES ('FARM_OWNER');

-- TARGET MARKET GROUP TYPES
INSERT INTO target_market_group_types (target_market_group_type_code) VALUES('PACKED');
INSERT INTO target_market_group_types (target_market_group_type_code) VALUES('SHIPPING');
INSERT INTO target_market_group_types (target_market_group_type_code) VALUES('MARKETING');
INSERT INTO target_market_group_types (target_market_group_type_code) VALUES('SALES');

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

-- UNITS OF MEASURE TYPE
INSERT INTO uom_types (code) VALUES ('INVENTORY');

-- CONTAINER_STACK_TYPES
INSERT INTO container_stack_types (stack_type_code, description) VALUES('S', 'Standard');
INSERT INTO container_stack_types (stack_type_code, description) VALUES('H', 'High');

-- REWORKS_RUN_TYPES
INSERT INTO reworks_run_types (run_type, description) VALUES('SINGLE PALLET EDIT', 'Single pallet edit');
INSERT INTO reworks_run_types (run_type, description) VALUES('BATCH PALLET EDIT', 'Batch pallet edit');
INSERT INTO reworks_run_types (run_type, description) VALUES('SCRAP PALLET', 'Scrap Pallet');
INSERT INTO reworks_run_types (run_type, description) VALUES('UNSCRAP PALLET', 'Unscrap Pallet');
INSERT INTO reworks_run_types (run_type, description) VALUES('REPACK PALLET', 'Repack Pallet');
INSERT INTO reworks_run_types (run_type, description) VALUES('BUILDUP', 'Buildup');
INSERT INTO reworks_run_types (run_type, description) VALUES('TIP BINS', 'Tip Bins');