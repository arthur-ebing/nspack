Sequel.migration do
  up do
    run <<~SQL
      DROP VIEW public.vw_pallets;
      CREATE OR REPLACE VIEW public.vw_pallets AS
        SELECT
            pallets.id AS pallet_id,
            fn_current_status ('pallets', pallets.id) AS pallet_status,
            pallets.pallet_number,
            --
            pallets.target_customer_party_role_id,
            fn_party_role_name (pallets.target_customer_party_role_id) AS target_customer,
            --
            fn_pallet_verification_failed (pallets.id) AS pallet_verification_failed,
            --
            pallets.in_stock,
            pallets.stock_created_at,
            --
            pallets.exit_ref,
            --
            pallets.location_id,
            locations.location_long_code,
            --
            pallets.pallet_format_id,
            pallet_bases.pallet_base_code,
            pallet_stack_types.stack_type_code,
            --
            pallets.carton_quantity AS pallet_carton_quantity,
            pallets.has_individual_cartons AS individual_cartons,
            --
            pallets.build_status,
            pallets.phc,
            pallets.intake_created_at,
            pallets.first_cold_storage_at,
            pallets.first_cold_storage_at::date AS first_cold_storage_date,
            --
            pallets.plt_packhouse_resource_id,
            plt_packhouses.plant_resource_code AS plant_packhouse,
            pallets.plt_line_resource_id,
            plt_lines.plant_resource_code AS plant_line,
            --
            pallets.nett_weight,
            pallets.gross_weight,
            pallets.gross_weight_measured_at,
            pallets.palletized,
            pallets.partially_palletized,
            pallets.palletized_at,
            pallets.palletized_at::date AS palletized_date,
            pallets.partially_palletized_at,
            pallets.partially_palletized_at::date AS partially_palletized_date,
            --
            floor(fn_calc_age_days (pallets.id, pallets.created_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS pallet_age,
            floor(fn_calc_age_days (pallets.id, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at), COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS inspection_age,
            floor(fn_calc_age_days (pallets.id, pallets.stock_created_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS stock_age,
            floor(fn_calc_age_days (pallets.id, pallets.first_cold_storage_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS cold_age,
            floor(fn_calc_age_days (pallets.id, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at), COALESCE(pallets.shipped_at, pallets.scrapped_at))) - floor(fn_calc_age_days (pallets.id, pallets.first_cold_storage_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS ambient_age,
            floor(fn_calc_age_days (pallets.id, pallets.govt_reinspection_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS reinspection_age,
            floor(fn_calc_age_days (pallets.id, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at), pallets.created_at)) AS pack_to_inspect_age,
            floor(fn_calc_age_days (pallets.id, pallets.first_cold_storage_at, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at))) AS inspect_to_cold_age,
            floor(fn_calc_age_days (pallets.id, COALESCE(pallets.first_cold_storage_at, COALESCE(pallets.shipped_at, pallets.scrapped_at)), COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at))) AS inspect_to_exit_warm_age,
            --
            pallets.cooled,
            pallets.temp_tail,
            pallets.depot_pallet,
            --
            pallets.fruit_sticker_pm_product_id,
            pm_products.product_code AS fruit_sticker,
            pallets.fruit_sticker_pm_product_2_id,
            pm_products_2.product_code AS fruit_sticker_2,
            --
            pallets.load_id,
            --
            pallets.allocated,
            pallets.allocated_at,
            pallets.shipped,
            pallets.shipped_at,
            pallets.shipped_at::date AS shipped_date,
            --
            pallets.inspected,
            pallets.last_govt_inspection_pallet_id,
            govt_inspection_pallets.govt_inspection_sheet_id,
            COALESCE(govt_inspection_sheets.inspection_point, pallets.edi_in_inspection_point) AS inspection_point,
            inspected_dest_country.country_name AS inspected_dest_country,
            pallets.govt_first_inspection_at,
            pallets.govt_first_inspection_at::date AS govt_first_inspection_date,
            pallets.govt_reinspection_at,
            pallets.govt_reinspection_at::date AS govt_reinspection_date,
            --
            pallets.internal_inspection_at,
            pallets.internal_reinspection_at,
            pallets.govt_inspection_passed,
            pallets.internal_inspection_passed,
            pallets.reinspected,
            --
            pallets.edi_in_transaction_id,
            edi_in_transactions.file_name AS edi_in_file,
            pallets.edi_in_consignment_note_number,
            pallets.edi_in_inspection_point,
            COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at)::date AS inspection_date,
            COALESCE(pallets.edi_in_consignment_note_number, 
                CASE WHEN pallets.govt_inspection_passed THEN
                    fn_consignment_note_number (govt_inspection_sheets.id)::text || ''
                ELSE
                    fn_consignment_note_number (govt_inspection_sheets.id)::text || 'F'
                END) AS addendum_manifest,
            --
            pallets.repacked AS pallet_repacked,
            pallets.repacked_at AS pallet_repacked_at,
            pallets.repacked_at::date AS pallet_repacked_date,
            --
            pallets.scrapped,
            pallets.scrapped_at,
            pallets.scrapped_at::date AS scrapped_date,
            --
            pallets.active,
            pallets.created_at,
            pallets.updated_at
        FROM
            pallets
            LEFT JOIN locations ON locations.id = pallets.location_id
            --
            LEFT JOIN pm_products ON pm_products.id = pallets.fruit_sticker_pm_product_id
            LEFT JOIN pm_products pm_products_2 ON pm_products_2.id = pallets.fruit_sticker_pm_product_2_id
            LEFT JOIN pallet_formats ON pallet_formats.id = pallets.pallet_format_id
            LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
            LEFT JOIN pallet_stack_types ON pallet_stack_types.id = pallet_formats.pallet_stack_type_id
            --
            LEFT JOIN plant_resources plt_packhouses ON plt_packhouses.id = pallets.plt_packhouse_resource_id
            LEFT JOIN plant_resources plt_lines ON plt_lines.id = pallets.plt_line_resource_id
            --
            LEFT JOIN edi_in_transactions ON edi_in_transactions.id = pallets.edi_in_transaction_id
            --
            LEFT JOIN govt_inspection_pallets ON govt_inspection_pallets.id = pallets.last_govt_inspection_pallet_id
            LEFT JOIN govt_inspection_sheets ON govt_inspection_sheets.id = govt_inspection_pallets.govt_inspection_sheet_id
            LEFT JOIN destination_countries inspected_dest_country ON inspected_dest_country.id = govt_inspection_sheets.destination_country_id;      
        ALTER TABLE public.vw_pallets OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP VIEW public.vw_pallets;
      CREATE OR REPLACE VIEW public.vw_pallets AS
        SELECT
            pallets.id AS pallet_id,
            fn_current_status ('pallets', pallets.id) AS pallet_status,
            pallets.pallet_number,
            --
            pallets.target_customer_party_role_id,
            fn_party_role_name (pallets.target_customer_party_role_id) AS target_customer,
            --
            fn_pallet_verification_failed (pallets.id) AS pallet_verification_failed,
            --
            pallets.in_stock,
            pallets.stock_created_at,
            --
            pallets.exit_ref,
            --
            pallets.location_id,
            locations.location_long_code,
            --
            pallets.pallet_format_id,
            pallet_bases.pallet_base_code,
            pallet_stack_types.stack_type_code,
            --
            pallets.carton_quantity AS pallet_carton_quantity,
            --
            pallets.build_status,
            pallets.phc,
            pallets.intake_created_at,
            pallets.first_cold_storage_at,
            pallets.first_cold_storage_at::date AS first_cold_storage_date,
            --
            pallets.plt_packhouse_resource_id,
            plt_packhouses.plant_resource_code AS plant_packhouse,
            pallets.plt_line_resource_id,
            plt_lines.plant_resource_code AS plant_line,
            --
            pallets.nett_weight,
            pallets.gross_weight,
            pallets.gross_weight_measured_at,
            pallets.palletized,
            pallets.partially_palletized,
            pallets.palletized_at,
            pallets.palletized_at::date AS palletized_date,
            pallets.partially_palletized_at,
            pallets.partially_palletized_at::date AS partially_palletized_date,
            --
            floor(fn_calc_age_days (pallets.id, pallets.created_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS pallet_age,
            floor(fn_calc_age_days (pallets.id, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at), COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS inspection_age,
            floor(fn_calc_age_days (pallets.id, pallets.stock_created_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS stock_age,
            floor(fn_calc_age_days (pallets.id, pallets.first_cold_storage_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS cold_age,
            floor(fn_calc_age_days (pallets.id, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at), COALESCE(pallets.shipped_at, pallets.scrapped_at))) - floor(fn_calc_age_days (pallets.id, pallets.first_cold_storage_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS ambient_age,
            floor(fn_calc_age_days (pallets.id, pallets.govt_reinspection_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS reinspection_age,
            floor(fn_calc_age_days (pallets.id, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at), pallets.created_at)) AS pack_to_inspect_age,
            floor(fn_calc_age_days (pallets.id, pallets.first_cold_storage_at, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at))) AS inspect_to_cold_age,
            floor(fn_calc_age_days (pallets.id, COALESCE(pallets.first_cold_storage_at, COALESCE(pallets.shipped_at, pallets.scrapped_at)), COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at))) AS inspect_to_exit_warm_age,
            --
            pallets.cooled,
            pallets.temp_tail,
            pallets.depot_pallet,
            --
            pallets.fruit_sticker_pm_product_id,
            pm_products.product_code AS fruit_sticker,
            pallets.fruit_sticker_pm_product_2_id,
            pm_products_2.product_code AS fruit_sticker_2,
            --
            pallets.load_id,
            --
            pallets.allocated,
            pallets.allocated_at,
            pallets.shipped,
            pallets.shipped_at,
            pallets.shipped_at::date AS shipped_date,
            --
            pallets.inspected,
            pallets.last_govt_inspection_pallet_id,
            govt_inspection_pallets.govt_inspection_sheet_id,
            COALESCE(govt_inspection_sheets.inspection_point, pallets.edi_in_inspection_point) AS inspection_point,
            inspected_dest_country.country_name AS inspected_dest_country,
            pallets.govt_first_inspection_at,
            pallets.govt_first_inspection_at::date AS govt_first_inspection_date,
            pallets.govt_reinspection_at,
            pallets.govt_reinspection_at::date AS govt_reinspection_date,
            --
            pallets.internal_inspection_at,
            pallets.internal_reinspection_at,
            pallets.govt_inspection_passed,
            pallets.internal_inspection_passed,
            pallets.reinspected,
            --
            pallets.edi_in_transaction_id,
            edi_in_transactions.file_name AS edi_in_file,
            pallets.edi_in_consignment_note_number,
            pallets.edi_in_inspection_point,
            COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at)::date AS inspection_date,
            COALESCE(pallets.edi_in_consignment_note_number, 
                CASE WHEN pallets.govt_inspection_passed THEN
                    fn_consignment_note_number (govt_inspection_sheets.id)::text || ''
                ELSE
                    fn_consignment_note_number (govt_inspection_sheets.id)::text || 'F'
                END) AS addendum_manifest,
            --
            pallets.repacked AS pallet_repacked,
            pallets.repacked_at AS pallet_repacked_at,
            pallets.repacked_at::date AS pallet_repacked_date,
            --
            pallets.scrapped,
            pallets.scrapped_at,
            pallets.scrapped_at::date AS scrapped_date,
            --
            pallets.active,
            pallets.created_at,
            pallets.updated_at
        FROM
            pallets
            LEFT JOIN locations ON locations.id = pallets.location_id
            --
            LEFT JOIN pm_products ON pm_products.id = pallets.fruit_sticker_pm_product_id
            LEFT JOIN pm_products pm_products_2 ON pm_products_2.id = pallets.fruit_sticker_pm_product_2_id
            LEFT JOIN pallet_formats ON pallet_formats.id = pallets.pallet_format_id
            LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
            LEFT JOIN pallet_stack_types ON pallet_stack_types.id = pallet_formats.pallet_stack_type_id
            --
            LEFT JOIN plant_resources plt_packhouses ON plt_packhouses.id = pallets.plt_packhouse_resource_id
            LEFT JOIN plant_resources plt_lines ON plt_lines.id = pallets.plt_line_resource_id
            --
            LEFT JOIN edi_in_transactions ON edi_in_transactions.id = pallets.edi_in_transaction_id
            --
            LEFT JOIN govt_inspection_pallets ON govt_inspection_pallets.id = pallets.last_govt_inspection_pallet_id
            LEFT JOIN govt_inspection_sheets ON govt_inspection_sheets.id = govt_inspection_pallets.govt_inspection_sheet_id
            LEFT JOIN destination_countries inspected_dest_country ON inspected_dest_country.id = govt_inspection_sheets.destination_country_id;      
        ALTER TABLE public.vw_pallets OWNER TO postgres;
    SQL
  end
end
