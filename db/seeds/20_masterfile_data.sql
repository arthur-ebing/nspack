-- ADDRESS TYPES
INSERT INTO public.address_types(address_type) VALUES ('Delivery Address') ON CONFLICT DO NOTHING;

-- CONTACT METHOD TYPES
INSERT INTO public.contact_method_types(contact_method_type) VALUES ('Tel') ON CONFLICT DO NOTHING;
INSERT INTO public.contact_method_types(contact_method_type) VALUES ('Fax') ON CONFLICT DO NOTHING;
INSERT INTO public.contact_method_types(contact_method_type) VALUES ('Cell') ON CONFLICT DO NOTHING;
INSERT INTO public.contact_method_types(contact_method_type) VALUES ('Email') ON CONFLICT DO NOTHING;

-- PM TYPE
INSERT INTO pm_types (pm_type_code, description) VALUES ('BIN', 'BIN') ON CONFLICT DO NOTHING;
INSERT INTO pm_types (pm_type_code, description) VALUES ('CARTON', 'CARTON') ON CONFLICT DO NOTHING;

-- PORT_TYPES
INSERT INTO port_types (port_type_code, description) VALUES('POL', 'Port of Loading') ON CONFLICT DO NOTHING;
INSERT INTO port_types (port_type_code, description) VALUES('POD', 'Port of Dispatch') ON CONFLICT DO NOTHING;
INSERT INTO port_types (port_type_code, description) VALUES('TRANSSHIP', 'Transfer Shipment') ON CONFLICT DO NOTHING;

-- ROLES
INSERT INTO roles (name) VALUES ('IMPLEMENTATION_OWNER') ON CONFLICT DO NOTHING;
INSERT INTO roles (name) VALUES ('TRANSPORTER') ON CONFLICT DO NOTHING;
INSERT INTO roles (name) VALUES ('OTHER') ON CONFLICT DO NOTHING;
INSERT INTO roles (name) VALUES ('CUSTOMER') ON CONFLICT DO NOTHING;
INSERT INTO roles (name) VALUES ('SUPPLIER') ON CONFLICT DO NOTHING;
INSERT INTO roles (name) VALUES ('MARKETER') ON CONFLICT DO NOTHING;
INSERT INTO roles (name) VALUES ('SHIPPING_LINE') ON CONFLICT DO NOTHING;
INSERT INTO roles (name) VALUES ('SHIPPER') ON CONFLICT DO NOTHING;
INSERT INTO roles (name) VALUES ('FINAL_RECEIVER') ON CONFLICT DO NOTHING;
INSERT INTO roles (name) VALUES ('EXPORTER') ON CONFLICT DO NOTHING;
INSERT INTO roles (name) VALUES ('BILLING_CLIENT') ON CONFLICT DO NOTHING;
INSERT INTO roles (name) VALUES ('CONSIGNEE') ON CONFLICT DO NOTHING;
INSERT INTO roles (name) VALUES ('HAULIER') ON CONFLICT DO NOTHING;
INSERT INTO roles (name) VALUES ('FARM_OWNER') ON CONFLICT DO NOTHING;
INSERT INTO roles (name) VALUES ('RMT_BIN_OWNER') ON CONFLICT DO NOTHING;
INSERT INTO roles (name) VALUES ('INSPECTOR') ON CONFLICT DO NOTHING;
INSERT INTO roles (name) VALUES ('INSPECTION_BILLING') ON CONFLICT DO NOTHING;

-- TARGET MARKET GROUP TYPES
INSERT INTO target_market_group_types (target_market_group_type_code) VALUES('PACKED') ON CONFLICT DO NOTHING;
INSERT INTO target_market_group_types (target_market_group_type_code) VALUES('SHIPPING') ON CONFLICT DO NOTHING;
INSERT INTO target_market_group_types (target_market_group_type_code) VALUES('MARKETING') ON CONFLICT DO NOTHING;
INSERT INTO target_market_group_types (target_market_group_type_code) VALUES('SALES') ON CONFLICT DO NOTHING;

-- VOYAGE_TYPES
INSERT INTO voyage_types (voyage_type_code, description) VALUES('ROAD', 'Trucks') ON CONFLICT DO NOTHING;
INSERT INTO voyage_types (voyage_type_code, description) VALUES('AIR', 'Air') ON CONFLICT DO NOTHING;
INSERT INTO voyage_types (voyage_type_code, description) VALUES('SEA', 'Sea') ON CONFLICT DO NOTHING;
INSERT INTO voyage_types (voyage_type_code, description) VALUES('RAIL', 'Rail') ON CONFLICT DO NOTHING;

-- VESSEL_TYPES
INSERT INTO vessel_types (voyage_type_id, vessel_type_code, description) VALUES((SELECT id FROM voyage_types WHERE voyage_type_code = 'ROAD'), 'TRUCK', 'Truck') ON CONFLICT DO NOTHING;
INSERT INTO vessel_types (voyage_type_id, vessel_type_code, description) VALUES((SELECT id FROM voyage_types WHERE voyage_type_code = 'SEA'), 'SHIP', 'Ship') ON CONFLICT DO NOTHING;
INSERT INTO vessel_types (voyage_type_id, vessel_type_code, description) VALUES((SELECT id FROM voyage_types WHERE voyage_type_code = 'RAIL'), 'TRAIN', 'Train') ON CONFLICT DO NOTHING;
INSERT INTO vessel_types (voyage_type_id, vessel_type_code, description) VALUES((SELECT id FROM voyage_types WHERE voyage_type_code = 'AIR'), 'AIRCRAFT', 'Aircraft') ON CONFLICT DO NOTHING;

-- UNITS OF MEASURE TYPE
INSERT INTO uom_types (code) VALUES ('INVENTORY') ON CONFLICT DO NOTHING;

-- CONTAINER_STACK_TYPES
INSERT INTO container_stack_types (stack_type_code, description) VALUES('S', 'Standard') ON CONFLICT DO NOTHING;
INSERT INTO container_stack_types (stack_type_code, description) VALUES('H', 'High') ON CONFLICT DO NOTHING;

-- REWORKS_RUN_TYPES
INSERT INTO reworks_run_types (run_type, description) VALUES('SINGLE PALLET EDIT', 'Single pallet edit') ON CONFLICT DO NOTHING;
INSERT INTO reworks_run_types (run_type, description) VALUES('BATCH PALLET EDIT', 'Batch pallet edit') ON CONFLICT DO NOTHING;
INSERT INTO reworks_run_types (run_type, description) VALUES('SCRAP PALLET', 'Scrap Pallet') ON CONFLICT DO NOTHING;
INSERT INTO reworks_run_types (run_type, description) VALUES('UNSCRAP PALLET', 'Unscrap Pallet') ON CONFLICT DO NOTHING;
INSERT INTO reworks_run_types (run_type, description) VALUES('REPACK PALLET', 'Repack Pallet') ON CONFLICT DO NOTHING;
INSERT INTO reworks_run_types (run_type, description) VALUES('BUILDUP', 'Buildup') ON CONFLICT DO NOTHING;
INSERT INTO reworks_run_types (run_type, description) VALUES('TIP BINS', 'Tip Bins') ON CONFLICT DO NOTHING;
INSERT INTO reworks_run_types (run_type, description) VALUES('WEIGH RMT BINS', 'Weigh Rmt Bins') ON CONFLICT DO NOTHING;
INSERT INTO reworks_run_types (run_type, description) VALUES('RECALC NETT WEIGHT', 'Recalc Nett Weight') ON CONFLICT DO NOTHING;
INSERT INTO reworks_run_types (run_type, description) VALUES('CHANGE DELIVERIES ORCHARDS', 'Change orchards on deliveries') ON CONFLICT DO NOTHING;
INSERT INTO reworks_run_types (run_type, description) VALUES('SCRAP BIN', 'Scrap Bin') ON CONFLICT DO NOTHING;
INSERT INTO reworks_run_types (run_type, description) VALUES('UNSCRAP BIN', 'Unscrap Bin') ON CONFLICT DO NOTHING;
INSERT INTO reworks_run_types (run_type, description) VALUES('BULK PRODUCTION RUN UPDATE', 'Bulk Production Run Update') ON CONFLICT DO NOTHING;

-- LOCATION TYPES
INSERT INTO location_types (location_type_code, short_code, hierarchical) VALUES('EMPTY_BIN', 'EMPTY_BIN', 'f') ON CONFLICT DO NOTHING;

-- LOCATION STORAGE TYPES
INSERT INTO location_storage_types (storage_type_code) VALUES('PALLETS') ON CONFLICT DO NOTHING;
INSERT INTO location_storage_types (storage_type_code) VALUES('RMT_PALLETS') ON CONFLICT DO NOTHING;

-- IN-TRANSIT LOCATION (Not part of locations tree)
INSERT INTO location_types (location_type_code, short_code, hierarchical) VALUES('IN_TRANSIT', 'IN_TRANSIT', 'f') ON CONFLICT DO NOTHING;
INSERT INTO location_storage_types (storage_type_code) VALUES('PALLETS') ON CONFLICT DO NOTHING;
INSERT INTO location_assignments (assignment_code) VALUES('TRANSIT') ON CONFLICT DO NOTHING;
INSERT INTO locations (primary_storage_type_id, location_type_id, primary_assignment_id, location_long_code, location_description, location_short_code, can_be_moved, can_store_stock)
VALUES ((SELECT id FROM location_storage_types WHERE storage_type_code = 'PALLETS'), (SELECT id FROM location_types WHERE location_type_code = 'IN_TRANSIT'), (SELECT id FROM location_assignments WHERE assignment_code = 'TRANSIT'), 'IN_TRANSIT_EX_PACKHSE', 'IN_TRANSIT_EX_PACKHSE', 'IN_TRANSIT_EX_PACKHSE', true, true) ON CONFLICT DO NOTHING;

-- BUSINESS PROCESSES
INSERT INTO business_processes(process, description) VALUES('MOVE_PALLET', 'ADHOC individual FG Pallet movements') ON CONFLICT DO NOTHING;
INSERT INTO business_processes(process, description) VALUES('MOVE_BIN', 'ADHOC RMT individual Bin movements') ON CONFLICT DO NOTHING;
INSERT INTO business_processes(process, description) VALUES('LOAD_SHIPPED', 'Load truck pallets shipped') ON CONFLICT DO NOTHING;

-- STOCK TYPES
INSERT INTO stock_types(stock_type_code, description) VALUES('PALLET', 'FG PALLETS') ON CONFLICT DO NOTHING;
INSERT INTO stock_types(stock_type_code, description) VALUES('BIN', 'RMT BINS') ON CONFLICT DO NOTHING;

INSERT INTO inspection_failure_types (failure_type_code) VALUES('GOVERNMENT') ON CONFLICT DO NOTHING;

-- USER_EMAIL_GROUPS --
INSERT INTO user_email_groups (mail_group) VALUES('label_approvers') ON CONFLICT DO NOTHING;
INSERT INTO user_email_groups (mail_group) VALUES('label_publishers') ON CONFLICT DO NOTHING;
INSERT INTO user_email_groups (mail_group) VALUES('edi_notifiers') ON CONFLICT DO NOTHING;

-- SCRAP_REASONS --
INSERT INTO scrap_reasons(scrap_reason, description) VALUES ('REPACKED', 'Repacked') ON CONFLICT DO NOTHING;
