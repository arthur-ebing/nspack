# frozen_string_literal: true

module MesscadaApp
  # Pallet Sequence dataset class.
  #
  # Provides a flat query for pallet sequences that can be used in
  # different ways without the overhead of using a view.
  #
  # Use like this:
  #
  #   filters = ['WHERE pallet_sequences.id = ?']
  #   query = MesscadaApp::DatasetPalletSequence.call(filters)
  #   DB[query, id].first
  class DatasetPalletSequence # rubocop:disable Metrics/ClassLength
    attr_reader :filter_conditions

    def initialize(filters)
      @filter_conditions = Array(filters)
      raise ArgumentError, "An array of filter conditions must be passed to #{self.class.name}" if @filter_conditions.empty?
    end

    def call
      <<~SQL
        #{sql_base}
        #{Array(filter_conditions).join("\n")}
      SQL
    end

    def self.call(filters)
      new(filters).call
    end

    private

    def sql_base
      <<~SQL
        SELECT
          pallet_sequences.id,
          pallet_sequences.pallet_number,
          pallet_sequences.pallet_sequence_number,
          pallet_sequences.standard_pack_code_id,
          pallet_sequences.basic_pack_code_id,
          pallet_sequences.grade_id,
          pallets.build_status,
          pallet_bases.pallet_base_code AS pallet_base,
          pallet_stack_types.stack_type_code AS stack_type,
          pallets.carton_quantity AS pallet_carton_quantity,
          pallet_sequences.carton_quantity,
          pallet_sequences.production_run_id,
          farms.farm_code AS farm,
          orchards.orchard_code AS orchard,
          commodities.code AS commodity,
          commodities.description AS commodity_description,
          cultivar_groups.cultivar_group_code AS cultivar_group,
          cultivars.cultivar_name AS cultivar,
          marketing_varieties.marketing_variety_code AS marketing_variety,
          fn_party_role_name(pallet_sequences.marketing_org_party_role_id) AS marketing_org,
          target_market_groups.target_market_group_name AS packed_tm_group,
          target_markets.target_market_name AS target_market,
          marks.mark_code AS mark,
          pm_marks.packaging_marks AS pm_mark,
          inventory_codes.inventory_code,
          cvv.marketing_variety_code AS customer_variety,
          std_fruit_size_counts.size_count_value AS std_size,
          fruit_size_references.size_reference AS size_ref,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          basic_pack_codes.basic_pack_code AS basic_pack,
          standard_pack_codes.standard_pack_code AS std_pack,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          pm_boms.bom_code AS bom,
          pallet_sequences.pallet_id,
          pallet_verification_failure_reasons.reason AS verification_failure_reason,
          pallet_sequences.verification_result,
          pm_products.product_code AS fruit_sticker,
          pallet_sequences.product_resource_allocation_id AS resource_allocation_id,
          pallets.gross_weight,
          pallets.nett_weight,
          pallet_sequences.nett_weight AS sequence_nett_weight,
          pallets.allocated,
          pallets.in_stock,
          pallet_sequences.marketing_order_number AS order_number,
          loads.customer_order_number,
          loads.customer_reference,
          fn_party_role_name(loads.customer_party_role_id) AS customer,
          vessels.vessel_code AS vessel,
          pol_ports.port_code AS pol,
          pod_ports.port_code AS pod,
          destination_cities.city_name AS final_destination,
          depots.depot_code AS depot,
          plt_packhouses.plant_resource_code AS plt_packhouse,
          plt_lines.plant_resource_code AS plt_line,
          pallets.location_id,
          locations.location_long_code::text AS location,
          pallets.shipped,
          pallets.inspected,
          pallets.reinspected,
          pallets.palletized,
          pallets.partially_palletized,
          floor(fn_calc_age_days(pallets.id, pallets.created_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS pallet_age,
          floor(fn_calc_age_days(pallets.id, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at), COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS inspection_age,
          floor(fn_calc_age_days(pallets.id, pallets.stock_created_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS stock_age,
          floor(fn_calc_age_days(pallets.id, pallets.first_cold_storage_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS cold_age,
          floor(fn_calc_age_days(pallets.id, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at), COALESCE(pallets.shipped_at, pallets.scrapped_at))) - floor(fn_calc_age_days(pallets.id, pallets.first_cold_storage_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS ambient_age,
          floor(fn_calc_age_days(pallets.id, pallets.govt_reinspection_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS reinspection_age,
          floor(fn_calc_age_days(pallets.id, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at), pallet_sequences.created_at)) AS pack_to_inspect_age,
          floor(fn_calc_age_days(pallets.id, pallets.first_cold_storage_at, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at))) AS inspect_to_cold_age,
          floor(fn_calc_age_days(pallets.id, COALESCE(pallets.first_cold_storage_at, COALESCE(pallets.shipped_at, pallets.scrapped_at)), COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at))) AS inspect_to_exit_warm_age,
          floor(fn_calc_age_days(pallets.id, pallets.verified_at, pallets.palletized_at)) AS palletized_to_verified_age,
          floor(fn_calc_age_days(pallets.id, pallets.govt_first_inspection_at, pallets.verified_at)) AS verified_to_inspected_age,
          floor(fn_calc_age_days(pallets.id, pallets.stock_created_at, pallets.govt_first_inspection_at)) AS inspected_to_in_stock_age,
          pallets.first_cold_storage_at,
          pallets.first_cold_storage_at::date AS first_cold_storage_date,
          pallets.govt_inspection_passed,
          pallets.govt_first_inspection_at,
          pallets.govt_first_inspection_at::date AS govt_first_inspection_date,
          pallets.govt_reinspection_at,
          pallets.govt_reinspection_at::date AS govt_reinspection_date,
          pallets.shipped_at,
          pallets.shipped_at::date AS shipped_date,
          pallet_sequences.created_at AS packed_at,
          pallet_sequences.created_at::date AS packed_date,
          to_char(pallet_sequences.created_at, 'IYYY--IW'::text) AS packed_week,
          pallet_sequences.created_at,
          pallet_sequences.updated_at,
          pallets.scrapped,
          pallets.scrapped_at,
          pallets.scrapped_at::date AS scrapped_date,
          farm_groups.farm_group_code AS farm_group,
          production_regions.production_region_code AS production_region,
          pucs.puc_code AS puc,
          std_fruit_size_counts.size_count_interval_group AS count_group,
          (pallet_sequences.carton_quantity * fruit_actual_counts_for_packs.actual_count_for_pack)::numeric / std_fruit_size_counts.size_count_value::numeric(9,5) AS std_ctns,
          pallet_sequences.product_resource_allocation_id AS resource_allocation_id,
          ( SELECT array_agg(t.treatment_code) AS array_agg
                 FROM pallet_sequences sq
                   JOIN treatments t ON t.id = ANY (sq.treatment_ids)
                WHERE sq.id = pallet_sequences.id
                GROUP BY sq.id) AS treatments,
          pallet_sequences.client_size_reference AS client_size_ref,
          pallet_sequences.client_product_code,
          seasons.season_code AS season,
          pm_subtypes.subtype_code AS pm_subtype,
          pm_types.pm_type_code AS pm_type,
          cartons_per_pallet.cartons_per_pallet AS cpp,
          pm_products_2.product_code AS fruit_sticker_2,
          pallets.gross_weight_measured_at,
          pallet_sequences.nett_weight AS sequence_nett_weight,
          pallets.exit_ref,
          pallets.phc,
          pallets.stock_created_at,
          pallets.intake_created_at,
          pallets.palletized_at,
          pallets.palletized_at::date AS palletized_date,
          pallets.partially_palletized_at,
          pallets.allocated_at,
          fn_pallet_verification_failed(pallets.id) AS pallet_verification_failed,
          pallet_sequences.verified,
          pallet_sequences.verification_passed,
          pallet_sequences.verified_at,
          pallet_sequences.extended_columns,
          pallet_sequences.scanned_from_carton_id AS scanned_carton,
          pallet_sequences.scrapped_at AS seq_scrapped_at,
          pallet_sequences.exit_ref AS seq_exit_ref,
          pallet_sequences.pick_ref,
          pallet_sequences.carton_quantity::numeric / pallets.carton_quantity::numeric AS pallet_size,
          fn_current_status('pallets'::text, pallets.id) AS status,
          fn_current_status('pallet_sequences'::text, pallet_sequences.id) AS sequence_status,
          pallets.active,
          pallets.load_id,
          voyages.voyage_code AS voyage,
          voyages.voyage_number,
          load_containers.container_code AS container,
          load_containers.internal_container_code AS internal_container,
          cargo_temperatures.temperature_code AS temp_code,
          load_vehicles.vehicle_number,
          pallets.first_cold_storage_at IS NOT NULL AS cooled,
          fn_party_role_name(loads.consignee_party_role_id) AS consignee,
          fn_party_role_name(loads.final_receiver_party_role_id) AS final_receiver,
          fn_party_role_name(loads.exporter_party_role_id) AS exporter,
          fn_party_role_name(loads.billing_client_party_role_id) AS billing_client,
          loads.exporter_certificate_code,
          loads.customer_reference,
          loads.order_number AS internal_order_number,
          destination_countries.country_name AS country,
          destination_regions.destination_region_name AS region,
          pod_voyage_ports.eta,
          pod_voyage_ports.ata,
          pol_voyage_ports.etd,
          pol_voyage_ports.atd,
          COALESCE(pod_voyage_ports.ata, pod_voyage_ports.eta) AS arrival_date,
          COALESCE(pol_voyage_ports.atd, pol_voyage_ports.etd) AS departure_date,
          COALESCE(pallets.load_id, 0) AS zero_load_id,
          pallets.fruit_sticker_pm_product_id,
          pallets.fruit_sticker_pm_product_2_id,
          pallet_sequences.pallet_verification_failure_reason_id,
          grades.grade_code AS grade,
          pallet_sequences.sell_by_code,
          pallet_sequences.product_chars,
          load_voyages.booking_reference,
          govt_inspection_pallets.govt_inspection_sheet_id,
          govt_inspection_pallets.id AS govt_inspection_pallet_id,
          COALESCE(govt_inspection_sheets.inspection_point, pallets.edi_in_inspection_point) AS inspection_point,
          inspected_dest_country.country_name AS inspected_dest_country,
          pallets.last_govt_inspection_pallet_id,
          pallets.pallet_format_id,
          pallets.temp_tail,
          fn_party_role_name(load_voyages.shipper_party_role_id) AS shipper,
          pallets.depot_pallet,
          edi_in_transactions.file_name AS edi_in_file,
          pallets.edi_in_consignment_note_number,
          COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at)::date AS inspection_date,
          COALESCE(pallets.edi_in_consignment_note_number,
              CASE
                  WHEN NOT pallets.govt_inspection_passed THEN govt_inspection_sheets.consignment_note_number || 'F'::text
                  WHEN pallets.govt_inspection_passed THEN govt_inspection_sheets.consignment_note_number
                  ELSE ''::text
              END) AS addendum_manifest,
          pallets.repacked,
          pallets.repacked_at,
          pallets.repacked_at::date AS repacked_date,
          pallet_sequences.repacked_from_pallet_id,
          repacked_from_pallets.pallet_number AS repacked_from_pallet_number,
          otmc.failed_otmc_results,
          otmc.failed_otmc,
          pallet_sequences.phyto_data,
          pallet_sequences.created_by,
          pallet_sequences.verified_by,
          fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
          govt_inspection_sheets.consignment_note_number,
          'DN'::text || loads.id::text AS dispatch_note,
          loads.edi_file_name AS po_file_name,
          palletizing_bays.plant_resource_code AS palletizing_bay,
          pallets.has_individual_cartons,
          marketing_pucs.puc_code AS marketing_puc,
          registered_orchards.orchard_code AS marketing_orchard,
          pallet_sequences.gtin_code,
          pallet_sequences.rmt_class_id,
          rmt_classes.rmt_class_code,
          pallet_sequences.packing_specification_item_id,
          fn_packing_specification_code(pallet_sequences.packing_specification_item_id) AS packing_specification_code,
          pallet_sequences.tu_labour_product_id,
          tu_pm_products.product_code AS tu_labour_product,
          pallet_sequences.ru_labour_product_id,
          ru_pm_products.product_code AS ru_labour_product,
          pallet_sequences.fruit_sticker_ids,
          ( SELECT array_agg(t.product_code ORDER BY t.product_code) AS array_agg
             FROM pm_products t
               JOIN pallet_sequences sq ON t.id = ANY (sq.fruit_sticker_ids)
            WHERE sq.id = pallet_sequences.id
            GROUP BY sq.id) AS fruit_stickers,
         pallet_sequences.tu_sticker_ids,
        ( SELECT array_agg(t.product_code ORDER BY t.product_code) AS array_agg
           FROM pm_products t
             JOIN pallet_sequences sq ON t.id = ANY (sq.tu_sticker_ids)
          WHERE sq.id = pallet_sequences.id
          GROUP BY sq.id) AS tu_stickers,
         pallet_sequences.target_customer_party_role_id,
         fn_party_role_name(pallet_sequences.target_customer_party_role_id) AS target_customer,
         pallets.batch_number

        FROM pallet_sequences
        JOIN pallets ON pallets.id = pallet_sequences.pallet_id
        LEFT JOIN pallets repacked_from_pallets ON repacked_from_pallets.id = pallet_sequences.repacked_from_pallet_id
        LEFT JOIN plant_resources plt_packhouses ON plt_packhouses.id = pallets.plt_packhouse_resource_id
        LEFT JOIN plant_resources plt_lines ON plt_lines.id = pallets.plt_line_resource_id
        LEFT JOIN plant_resources packhouses ON packhouses.id = pallet_sequences.packhouse_resource_id
        LEFT JOIN plant_resources lines ON lines.id = pallet_sequences.production_line_id
        LEFT JOIN plant_resources palletizing_bays ON palletizing_bays.id = pallets.palletizing_bay_resource_id
        JOIN locations ON locations.id = pallets.location_id
        JOIN farms ON farms.id = pallet_sequences.farm_id
        LEFT JOIN farm_groups ON farms.farm_group_id = farm_groups.id
        JOIN production_regions ON production_regions.id = farms.pdn_region_id
        JOIN pucs ON pucs.id = pallet_sequences.puc_id
        JOIN orchards ON orchards.id = pallet_sequences.orchard_id
        JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
        LEFT JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
        LEFT JOIN commodities ON commodities.id = COALESCE(cultivars.commodity_id, cultivar_groups.commodity_id)
        JOIN marketing_varieties ON marketing_varieties.id = pallet_sequences.marketing_variety_id
        JOIN marks ON marks.id = pallet_sequences.mark_id
        LEFT JOIN pm_marks ON pm_marks.id = pallet_sequences.pm_mark_id
        JOIN inventory_codes ON inventory_codes.id = pallet_sequences.inventory_code_id
        JOIN target_market_groups ON target_market_groups.id = pallet_sequences.packed_tm_group_id
        LEFT JOIN target_markets ON target_markets.id = pallet_sequences.target_market_id
        JOIN grades ON grades.id = pallet_sequences.grade_id
        LEFT JOIN customer_varieties ON customer_varieties.id = pallet_sequences.customer_variety_id
        LEFT JOIN marketing_varieties cvv ON cvv.id = customer_varieties.variety_as_customer_variety_id
        LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = pallet_sequences.std_fruit_size_count_id
        LEFT JOIN fruit_size_references ON fruit_size_references.id = pallet_sequences.fruit_size_reference_id
        LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = pallet_sequences.fruit_actual_counts_for_pack_id
        JOIN basic_pack_codes ON basic_pack_codes.id = pallet_sequences.basic_pack_code_id
        JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
        LEFT JOIN pm_boms ON pm_boms.id = pallet_sequences.pm_bom_id
        LEFT JOIN pm_subtypes ON pm_subtypes.id = pallet_sequences.pm_subtype_id
        LEFT JOIN pm_types ON pm_types.id = pallet_sequences.pm_type_id
        JOIN seasons ON seasons.id = pallet_sequences.season_id
        JOIN cartons_per_pallet ON cartons_per_pallet.id = pallet_sequences.cartons_per_pallet_id
        LEFT JOIN pm_products ON pm_products.id = pallets.fruit_sticker_pm_product_id
        LEFT JOIN pm_products pm_products_2 ON pm_products_2.id = pallets.fruit_sticker_pm_product_2_id
        LEFT JOIN pallet_formats ON pallet_formats.id = pallets.pallet_format_id
        LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
        LEFT JOIN pallet_stack_types ON pallet_stack_types.id = pallet_formats.pallet_stack_type_id
        LEFT JOIN pallet_verification_failure_reasons ON pallet_verification_failure_reasons.id = pallet_sequences.pallet_verification_failure_reason_id
        LEFT JOIN loads ON loads.id = pallets.load_id
        LEFT JOIN load_voyages ON loads.id = load_voyages.load_id
        LEFT JOIN voyage_ports pol_voyage_ports ON pol_voyage_ports.id = loads.pol_voyage_port_id
        LEFT JOIN voyage_ports pod_voyage_ports ON pod_voyage_ports.id = loads.pod_voyage_port_id
        LEFT JOIN voyages ON voyages.id = pol_voyage_ports.voyage_id
        LEFT JOIN vessels ON vessels.id = voyages.vessel_id
        LEFT JOIN load_containers ON load_containers.load_id = loads.id
        LEFT JOIN load_vehicles ON load_vehicles.load_id = loads.id
        LEFT JOIN destination_cities ON destination_cities.id = loads.final_destination_id
        LEFT JOIN destination_countries ON destination_countries.id = destination_cities.destination_country_id
        LEFT JOIN destination_regions ON destination_regions.id = destination_countries.destination_region_id
        LEFT JOIN cargo_temperatures ON cargo_temperatures.id = load_containers.cargo_temperature_id
        LEFT JOIN govt_inspection_pallets ON govt_inspection_pallets.id = pallets.last_govt_inspection_pallet_id
        LEFT JOIN govt_inspection_sheets ON govt_inspection_sheets.id = govt_inspection_pallets.govt_inspection_sheet_id
        LEFT JOIN destination_countries inspected_dest_country ON inspected_dest_country.id = govt_inspection_sheets.destination_country_id
        LEFT JOIN edi_in_transactions ON edi_in_transactions.id = pallets.edi_in_transaction_id
        LEFT JOIN ports pol_ports ON pol_ports.id = pol_voyage_ports.port_id
        LEFT JOIN ports pod_ports ON pod_ports.id = pod_voyage_ports.port_id
        LEFT JOIN depots ON depots.id = loads.depot_id
        LEFT JOIN ( SELECT sq.id,
               COALESCE(btrim(array_agg(orchard_test_types.test_type_code)::text), ''::text) <> ''::text AS failed_otmc,
               array_agg(orchard_test_types.test_type_code) AS failed_otmc_results
              FROM pallet_sequences sq
                JOIN orchard_test_types ON orchard_test_types.id = ANY (sq.failed_otmc_results)
             GROUP BY sq.id) otmc ON otmc.id = pallet_sequences.id
        LEFT JOIN pucs marketing_pucs ON marketing_pucs.id = pallet_sequences.marketing_puc_id
        LEFT JOIN registered_orchards ON registered_orchards.id = pallet_sequences.marketing_orchard_id
        LEFT JOIN rmt_classes ON rmt_classes.id = pallet_sequences.rmt_class_id
        LEFT JOIN pm_products tu_pm_products ON tu_pm_products.id = pallet_sequences.tu_labour_product_id
        LEFT JOIN pm_products ru_pm_products ON ru_pm_products.id = pallet_sequences.ru_labour_product_id

      SQL
    end
  end
end
