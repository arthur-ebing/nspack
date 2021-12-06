Sequel.migration do
  up do
    run <<~SQL
      CREATE VIEW public.vw_offsite_bin_asset_transactions AS
        SELECT bin_loads.id,        
               'ISSUE_BINS' AS transaction_type_code,
               'BIN SALES' AS process,
               bin_loads.id::text AS reference_number,
               bin_loads.customer_party_role_id AS party_role_id,
               fn_party_role_name(bin_loads.customer_party_role_id) AS material_owner,
               rmt_bins.rmt_container_material_type_id,
               rcmt.container_material_type_code,
               rmt_container_material_owners.id AS rmt_container_material_owner_id,
               (SELECT locations.id FROM locations
                JOIN location_types ON location_types.id = locations.location_type_id
                WHERE location_types.location_type_code = 'BIN_ASSET'
                AND locations.location_long_code = 'ONSITE_FULL_BIN') AS from_location_id,
               (SELECT locations.location_long_code FROM locations
                JOIN location_types ON location_types.id = locations.location_type_id
                WHERE location_types.location_type_code = 'BIN_ASSET'
                AND locations.location_long_code = 'ONSITE_FULL_BIN') AS from_location,
               to_locations.id AS to_location_id,
               to_locations.location_long_code AS to_location,
               SUM(rmt_bins.qty_bins) AS quantity_bins,
               bin_loads.created_at
        FROM rmt_bins
        LEFT JOIN bin_load_products ON rmt_bins.bin_load_product_id = bin_load_products.id
        LEFT JOIN bin_loads ON bin_load_products.bin_load_id = bin_loads.id
        LEFT JOIN rmt_container_material_types rcmt ON rmt_bins.rmt_container_material_type_id = rcmt.id
        LEFT JOIN rmt_container_material_owners ON rmt_container_material_owners.rmt_container_material_type_id = rmt_bins.rmt_container_material_type_id
              AND rmt_container_material_owners.rmt_material_owner_party_role_id = bin_loads.customer_party_role_id
        LEFT JOIN ( SELECT locations.id, locations.location_long_code FROM locations
                    JOIN location_types ON location_types.id = locations.location_type_id
                    WHERE location_types.location_type_code = 'BIN_ASSET_TRADING_PARTNER') to_locations ON to_locations.location_long_code = fn_party_role_name(bin_loads.customer_party_role_id)
        WHERE rmt_bins.bin_load_product_id IS NOT NULL
        GROUP BY bin_loads.id, rmt_bins.rmt_container_material_type_id, rcmt.container_material_type_code, rmt_container_material_owners.id,
                 from_location_id, from_location, to_locations.id, to_locations.location_long_code
        UNION ALL
        SELECT bin_asset_transaction_items.id,
               asset_transaction_types.transaction_type_code,
               business_processes.process,
               bin_asset_transactions.reference_number,
               rmt_container_material_owners.rmt_material_owner_party_role_id AS party_role_id,
               fn_party_role_name(rmt_container_material_owners.rmt_material_owner_party_role_id) AS material_owner,
               rmt_container_material_owners.rmt_container_material_type_id,
               rcmt.container_material_type_code,
               bin_asset_transaction_items.rmt_container_material_owner_id,
               bin_asset_transaction_items.bin_asset_from_location_id AS from_location_id,
               from_locations.location_long_code AS from_location,
               bin_asset_transaction_items.bin_asset_to_location_id AS to_location_id,
               to_locations.location_long_code AS to_location,
               bin_asset_transaction_items.quantity_bins,
               bin_asset_transactions.created_at
        FROM bin_asset_transaction_items
        LEFT JOIN locations from_locations ON from_locations.id = bin_asset_transaction_items.bin_asset_from_location_id
        LEFT JOIN locations to_locations ON to_locations.id = bin_asset_transaction_items.bin_asset_to_location_id
        LEFT JOIN bin_asset_transactions ON bin_asset_transactions.id = bin_asset_transaction_items.bin_asset_transaction_id
        LEFT JOIN asset_transaction_types ON asset_transaction_types.id = bin_asset_transactions.asset_transaction_type_id
        LEFT JOIN rmt_container_material_owners ON rmt_container_material_owners.id = bin_asset_transaction_items.rmt_container_material_owner_id
        LEFT JOIN rmt_container_material_types rcmt on rmt_container_material_owners.rmt_container_material_type_id = rcmt.id
        LEFT JOIN business_processes ON business_processes.id = bin_asset_transactions.business_process_id
        LEFT JOIN rmt_deliveries rd on bin_asset_transactions.fruit_reception_delivery_id = rd.id
        LEFT JOIN orchards o on rd.orchard_id = o.id
        LEFT JOIN farms f on o.farm_id = f.id
        WHERE bin_asset_transactions.business_process_id NOT IN (SELECT id FROM business_processes WHERE process = 'BIN_ASSET_CONTROL')
          AND bin_asset_transactions.reference_number NOT IN ('take-on2');
        
      ALTER TABLE public.vw_offsite_bin_asset_transactions
      OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP VIEW public.vw_offsite_bin_asset_transactions;
    SQL
  end
end
