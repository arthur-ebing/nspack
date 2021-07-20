Sequel.migration do
  up do
    run <<~SQL
      DROP VIEW public.vw_cartons;

      CREATE OR REPLACE VIEW public.vw_cartons AS
      SELECT cartons.id AS carton_id,
        carton_labels.id AS carton_label_id,
        carton_labels.production_run_id,
        carton_labels.created_at AS carton_label_created_at,
        ABS(date_part('epoch', current_timestamp - carton_labels.created_at) / 3600)::int AS label_age_hrs,
        ABS(date_part('epoch', current_timestamp - cartons.created_at) / 3600)::int AS carton_age_hrs,
        CONCAT(contract_workers.first_name, '_', contract_workers.surname) AS contract_worker,
        cartons.created_at AS carton_verified_at,
        packhouses.plant_resource_code AS packhouse,
        lines.plant_resource_code AS line,
        packpoints.plant_resource_code AS packpoint,
        palletizing_bays.plant_resource_code AS palletizing_bay,
        system_resources.system_resource_code AS print_device,
        carton_labels.label_name,
        farms.farm_code,
        pucs.puc_code,
        orchards.orchard_code,
        commodities.code AS commodity_code,
        cultivar_groups.cultivar_group_code,
        cultivars.cultivar_name,
        cultivars.cultivar_code,
        marketing_varieties.marketing_variety_code,
        cvv.marketing_variety_code AS customer_variety_code,
        std_fruit_size_counts.size_count_value AS std_size,
        fruit_size_references.size_reference AS size_ref,
        fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
        basic_pack_codes.basic_pack_code,
        standard_pack_codes.standard_pack_code,
        fn_party_role_name(carton_labels.marketing_org_party_role_id) AS marketer,
        marks.mark_code,
        pm_marks.packaging_marks,
        inventory_codes.inventory_code,
        carton_labels.product_resource_allocation_id AS resource_allocation_id,
        product_setup_templates.template_name AS product_setup_template,
        pm_boms.bom_code AS pm_bom,
        pm_boms.system_code AS pm_bom_system_code,
        ( SELECT array_agg(t.treatment_code ORDER BY t.treatment_code) AS array_agg
          FROM treatments t
          JOIN carton_labels cl ON t.id = ANY (cl.treatment_ids)
          WHERE cl.id = carton_labels.id
          GROUP BY cl.id) AS treatment_codes,
        carton_labels.client_size_reference AS client_size_ref,
        carton_labels.client_product_code,
        carton_labels.marketing_order_number,
        target_market_groups.target_market_group_name AS packed_tm_group,
        target_markets.target_market_name AS target_market,
        seasons.season_code,
        pm_subtypes.subtype_code,
        pm_types.pm_type_code,
        cartons_per_pallet.cartons_per_pallet,
        pm_products.product_code,
        cartons.gross_weight,
        cartons.nett_weight,
        carton_labels.pick_ref,
        cartons.pallet_sequence_id,
        COALESCE(carton_labels.pallet_number, ( SELECT pallet_sequences.pallet_number
                FROM pallet_sequences
                WHERE pallet_sequences.id = cartons.pallet_sequence_id)) AS pallet_number,
        ( SELECT pallet_sequences.pallet_sequence_number
               FROM pallet_sequences
               WHERE pallet_sequences.id = cartons.pallet_sequence_id) AS pallet_sequence_number,
        personnel_identifiers.identifier AS personnel_identifier,
        contract_workers.personnel_number,
        packing_methods.packing_method_code,
        palletizers.identifier AS palletizer_identifier,
        CONCAT(palletizer_contract_workers.first_name, '_', palletizer_contract_workers.surname) AS palletizer_contract_worker,
        palletizer_contract_workers.personnel_number AS palletizer_personnel_number,
        cartons.is_virtual,
        carton_labels.group_incentive_id,
        carton_labels.marketing_puc_id,
        marketing_pucs.puc_code AS marketing_puc,
        carton_labels.marketing_orchard_id,
        registered_orchards.orchard_code AS marketing_orchard,
        carton_labels.rmt_bin_id,
        carton_labels.dp_carton,
        carton_labels.gtin_code,
        carton_labels.rmt_class_id,
        rmt_classes.rmt_class_code,
        carton_labels.packing_specification_item_id,
        fn_packing_specification_code(carton_labels.packing_specification_item_id) AS packing_specification_code,
        carton_labels.tu_labour_product_id,
        tu_pm_products.product_code AS tu_labour_product,
        carton_labels.ru_labour_product_id,
        ru_pm_products.product_code AS ru_labour_product,
        carton_labels.fruit_sticker_ids,
        ( SELECT array_agg(t.product_code ORDER BY t.product_code) AS array_agg
          FROM pm_products t
          JOIN carton_labels cl ON t.id = ANY (cl.fruit_sticker_ids)
          WHERE cl.id = carton_labels.id
          GROUP BY cl.id) AS fruit_stickers,
        carton_labels.tu_sticker_ids,
        ( SELECT array_agg(t.product_code ORDER BY t.product_code) AS array_agg
          FROM pm_products t
          JOIN carton_labels cl ON t.id = ANY (cl.tu_sticker_ids)
          WHERE cl.id = carton_labels.id
          GROUP BY cl.id) AS tu_stickers,
        carton_labels.target_customer_party_role_id,
        fn_party_role_name(carton_labels.target_customer_party_role_id) AS target_customer,
        carton_labels.rmt_container_material_owner_id,
        CONCAT(container_material_type_code, ' - ', fn_party_role_name(rmt_material_owner_party_role_id)) AS rmt_container_material_owner
        
       FROM carton_labels
         LEFT JOIN cartons ON carton_labels.id = cartons.carton_label_id
         JOIN production_runs ON production_runs.id = carton_labels.production_run_id
         JOIN product_setup_templates ON product_setup_templates.id = production_runs.product_setup_template_id
         JOIN plant_resources packhouses ON packhouses.id = carton_labels.packhouse_resource_id
         JOIN plant_resources lines ON lines.id = carton_labels.production_line_id
         LEFT JOIN plant_resources packpoints ON packpoints.id = carton_labels.resource_id
         LEFT JOIN plant_resources palletizing_bays ON palletizing_bays.id = cartons.palletizing_bay_resource_id
         LEFT JOIN system_resources ON packpoints.system_resource_id = system_resources.id
         JOIN farms ON farms.id = carton_labels.farm_id
         JOIN pucs ON pucs.id = carton_labels.puc_id
         JOIN orchards ON orchards.id = carton_labels.orchard_id
         JOIN cultivar_groups ON cultivar_groups.id = carton_labels.cultivar_group_id
         LEFT JOIN cultivars ON cultivars.id = carton_labels.cultivar_id
         LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
         JOIN marketing_varieties ON marketing_varieties.id = carton_labels.marketing_variety_id
         LEFT JOIN customer_varieties ON customer_varieties.id = carton_labels.customer_variety_id
         LEFT JOIN marketing_varieties cvv ON cvv.id = customer_varieties.variety_as_customer_variety_id
         LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = carton_labels.std_fruit_size_count_id
         LEFT JOIN fruit_size_references ON fruit_size_references.id = carton_labels.fruit_size_reference_id
         LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = carton_labels.fruit_actual_counts_for_pack_id
         JOIN basic_pack_codes ON basic_pack_codes.id = carton_labels.basic_pack_code_id
         JOIN standard_pack_codes ON standard_pack_codes.id = carton_labels.standard_pack_code_id
         JOIN marks ON marks.id = carton_labels.mark_id
         LEFT JOIN pm_marks ON pm_marks.id = carton_labels.pm_mark_id
         JOIN inventory_codes ON inventory_codes.id = carton_labels.inventory_code_id
         LEFT JOIN pm_boms ON pm_boms.id = carton_labels.pm_bom_id
         LEFT JOIN pm_subtypes ON pm_subtypes.id = carton_labels.pm_subtype_id
         LEFT JOIN pm_types ON pm_types.id = carton_labels.pm_type_id
         JOIN target_market_groups ON target_market_groups.id = carton_labels.packed_tm_group_id
         LEFT JOIN target_markets ON target_markets.id = carton_labels.target_market_id
         JOIN seasons ON seasons.id = carton_labels.season_id
         JOIN cartons_per_pallet ON cartons_per_pallet.id = carton_labels.cartons_per_pallet_id
         LEFT JOIN pm_products ON pm_products.id = carton_labels.fruit_sticker_pm_product_id
         JOIN pallet_formats ON pallet_formats.id = carton_labels.pallet_format_id
         LEFT JOIN contract_workers ON contract_workers.id = carton_labels.contract_worker_id
         LEFT JOIN personnel_identifiers ON personnel_identifiers.id = carton_labels.personnel_identifier_id
         JOIN packing_methods ON packing_methods.id = carton_labels.packing_method_id
         LEFT JOIN personnel_identifiers palletizers ON palletizers.id = cartons.palletizer_identifier_id
         LEFT JOIN contract_workers palletizer_contract_workers ON palletizer_contract_workers.id = cartons.palletizer_contract_worker_id
         LEFT JOIN group_incentives ON group_incentives.id = carton_labels.group_incentive_id
         LEFT JOIN pucs marketing_pucs ON marketing_pucs.id = carton_labels.marketing_puc_id
         LEFT JOIN registered_orchards ON registered_orchards.id = carton_labels.marketing_orchard_id
         LEFT JOIN rmt_classes ON rmt_classes.id = carton_labels.rmt_class_id
         LEFT JOIN pm_products tu_pm_products ON tu_pm_products.id = carton_labels.tu_labour_product_id
         LEFT JOIN pm_products ru_pm_products ON ru_pm_products.id = carton_labels.ru_labour_product_id
         LEFT JOIN rmt_container_material_owners ON rmt_container_material_owners.id = carton_labels.rmt_container_material_owner_id
         LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_container_material_owners.rmt_container_material_type_id;

       ALTER TABLE public.vw_cartons
        OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP VIEW public.vw_cartons;

      CREATE OR REPLACE VIEW public.vw_cartons AS
      SELECT cartons.id AS carton_id,
        carton_labels.id AS carton_label_id,
        carton_labels.production_run_id,
        carton_labels.created_at AS carton_label_created_at,
        ABS(date_part('epoch', current_timestamp - carton_labels.created_at) / 3600)::int AS label_age_hrs,
        ABS(date_part('epoch', current_timestamp - cartons.created_at) / 3600)::int AS carton_age_hrs,
        CONCAT(contract_workers.first_name, '_', contract_workers.surname) AS contract_worker,
        cartons.created_at AS carton_verified_at,
        packhouses.plant_resource_code AS packhouse,
        lines.plant_resource_code AS line,
        packpoints.plant_resource_code AS packpoint,
        palletizing_bays.plant_resource_code AS palletizing_bay,
        system_resources.system_resource_code AS print_device,
        carton_labels.label_name,
        farms.farm_code,
        pucs.puc_code,
        orchards.orchard_code,
        commodities.code AS commodity_code,
        cultivar_groups.cultivar_group_code,
        cultivars.cultivar_name,
        cultivars.cultivar_code,
        marketing_varieties.marketing_variety_code,
        cvv.marketing_variety_code AS customer_variety_code,
        std_fruit_size_counts.size_count_value AS std_size,
        fruit_size_references.size_reference AS size_ref,
        fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
        basic_pack_codes.basic_pack_code,
        standard_pack_codes.standard_pack_code,
        fn_party_role_name(carton_labels.marketing_org_party_role_id) AS marketer,
        marks.mark_code,
        pm_marks.packaging_marks,
        inventory_codes.inventory_code,
        carton_labels.product_resource_allocation_id AS resource_allocation_id,
        product_setup_templates.template_name AS product_setup_template,
        pm_boms.bom_code AS pm_bom,
        pm_boms.system_code AS pm_bom_system_code,
        ( SELECT array_agg(t.treatment_code ORDER BY t.treatment_code) AS array_agg
          FROM treatments t
          JOIN carton_labels cl ON t.id = ANY (cl.treatment_ids)
          WHERE cl.id = carton_labels.id
          GROUP BY cl.id) AS treatment_codes,
        carton_labels.client_size_reference AS client_size_ref,
        carton_labels.client_product_code,
        carton_labels.marketing_order_number,
        target_market_groups.target_market_group_name AS packed_tm_group,
        target_markets.target_market_name AS target_market,
        seasons.season_code,
        pm_subtypes.subtype_code,
        pm_types.pm_type_code,
        cartons_per_pallet.cartons_per_pallet,
        pm_products.product_code,
        cartons.gross_weight,
        cartons.nett_weight,
        carton_labels.pick_ref,
        cartons.pallet_sequence_id,
        COALESCE(carton_labels.pallet_number, ( SELECT pallet_sequences.pallet_number
                FROM pallet_sequences
                WHERE pallet_sequences.id = cartons.pallet_sequence_id)) AS pallet_number,
        ( SELECT pallet_sequences.pallet_sequence_number
               FROM pallet_sequences
               WHERE pallet_sequences.id = cartons.pallet_sequence_id) AS pallet_sequence_number,
        personnel_identifiers.identifier AS personnel_identifier,
        contract_workers.personnel_number,
        packing_methods.packing_method_code,
        palletizers.identifier AS palletizer_identifier,
        CONCAT(palletizer_contract_workers.first_name, '_', palletizer_contract_workers.surname) AS palletizer_contract_worker,
        palletizer_contract_workers.personnel_number AS palletizer_personnel_number,
        cartons.is_virtual,
        carton_labels.group_incentive_id,
        carton_labels.marketing_puc_id,
        marketing_pucs.puc_code AS marketing_puc,
        carton_labels.marketing_orchard_id,
        registered_orchards.orchard_code AS marketing_orchard,
        carton_labels.rmt_bin_id,
        carton_labels.dp_carton,
        carton_labels.gtin_code,
        carton_labels.rmt_class_id,
        rmt_classes.rmt_class_code,
        carton_labels.packing_specification_item_id,
        fn_packing_specification_code(carton_labels.packing_specification_item_id) AS packing_specification_code,
        carton_labels.tu_labour_product_id,
        tu_pm_products.product_code AS tu_labour_product,
        carton_labels.ru_labour_product_id,
        ru_pm_products.product_code AS ru_labour_product,
        carton_labels.fruit_sticker_ids,
        ( SELECT array_agg(t.product_code ORDER BY t.product_code) AS array_agg
          FROM pm_products t
          JOIN carton_labels cl ON t.id = ANY (cl.fruit_sticker_ids)
          WHERE cl.id = carton_labels.id
          GROUP BY cl.id) AS fruit_stickers,
        carton_labels.tu_sticker_ids,
        ( SELECT array_agg(t.product_code ORDER BY t.product_code) AS array_agg
          FROM pm_products t
          JOIN carton_labels cl ON t.id = ANY (cl.tu_sticker_ids)
          WHERE cl.id = carton_labels.id
          GROUP BY cl.id) AS tu_stickers,
        carton_labels.target_customer_party_role_id,
        fn_party_role_name(carton_labels.target_customer_party_role_id) AS target_customer,
        carton_labels.rmt_container_material_owner_id,
        CONCAT(container_material_type_code, ' - ', fn_party_role_name(rmt_material_owner_party_role_id)) AS rmt_container_material_owner
        
       FROM carton_labels
         LEFT JOIN cartons ON carton_labels.id = cartons.carton_label_id
         JOIN production_runs ON production_runs.id = carton_labels.production_run_id
         JOIN product_setup_templates ON product_setup_templates.id = production_runs.product_setup_template_id
         JOIN plant_resources packhouses ON packhouses.id = carton_labels.packhouse_resource_id
         JOIN plant_resources lines ON lines.id = carton_labels.production_line_id
         LEFT JOIN plant_resources packpoints ON packpoints.id = carton_labels.resource_id
         LEFT JOIN plant_resources palletizing_bays ON palletizing_bays.id = cartons.palletizing_bay_resource_id
         LEFT JOIN system_resources ON packpoints.system_resource_id = system_resources.id
         JOIN farms ON farms.id = carton_labels.farm_id
         JOIN pucs ON pucs.id = carton_labels.puc_id
         JOIN orchards ON orchards.id = carton_labels.orchard_id
         JOIN cultivar_groups ON cultivar_groups.id = carton_labels.cultivar_group_id
         LEFT JOIN cultivars ON cultivars.id = carton_labels.cultivar_id
         LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
         JOIN marketing_varieties ON marketing_varieties.id = carton_labels.marketing_variety_id
         LEFT JOIN customer_varieties ON customer_varieties.id = carton_labels.customer_variety_id
         LEFT JOIN marketing_varieties cvv ON cvv.id = customer_varieties.variety_as_customer_variety_id
         LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = carton_labels.std_fruit_size_count_id
         LEFT JOIN fruit_size_references ON fruit_size_references.id = carton_labels.fruit_size_reference_id
         LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = carton_labels.fruit_actual_counts_for_pack_id
         JOIN basic_pack_codes ON basic_pack_codes.id = carton_labels.basic_pack_code_id
         JOIN standard_pack_codes ON standard_pack_codes.id = carton_labels.standard_pack_code_id
         JOIN marks ON marks.id = carton_labels.mark_id
         LEFT JOIN pm_marks ON pm_marks.id = carton_labels.pm_mark_id
         JOIN inventory_codes ON inventory_codes.id = carton_labels.inventory_code_id
         LEFT JOIN pm_boms ON pm_boms.id = carton_labels.pm_bom_id
         LEFT JOIN pm_subtypes ON pm_subtypes.id = carton_labels.pm_subtype_id
         LEFT JOIN pm_types ON pm_types.id = carton_labels.pm_type_id
         JOIN target_market_groups ON target_market_groups.id = carton_labels.packed_tm_group_id
         LEFT JOIN target_markets ON target_markets.id = carton_labels.target_market_id
         JOIN seasons ON seasons.id = carton_labels.season_id
         JOIN cartons_per_pallet ON cartons_per_pallet.id = carton_labels.cartons_per_pallet_id
         LEFT JOIN pm_products ON pm_products.id = carton_labels.fruit_sticker_pm_product_id
         JOIN pallet_formats ON pallet_formats.id = carton_labels.pallet_format_id
         LEFT JOIN contract_workers ON contract_workers.id = carton_labels.contract_worker_id
         LEFT JOIN personnel_identifiers ON personnel_identifiers.id = carton_labels.personnel_identifier_id
         JOIN packing_methods ON packing_methods.id = carton_labels.packing_method_id
         LEFT JOIN personnel_identifiers palletizers ON palletizers.id = cartons.palletizer_identifier_id
         LEFT JOIN contract_workers palletizer_contract_workers ON palletizer_contract_workers.id = cartons.palletizer_contract_worker_id
         LEFT JOIN group_incentives ON group_incentives.id = carton_labels.group_incentive_id
         LEFT JOIN pucs marketing_pucs ON marketing_pucs.id = carton_labels.marketing_puc_id
         LEFT JOIN registered_orchards ON registered_orchards.id = carton_labels.marketing_orchard_id
         LEFT JOIN rmt_classes ON rmt_classes.id = carton_labels.rmt_class_id
         LEFT JOIN pm_products tu_pm_products ON tu_pm_products.id = carton_labels.tu_labour_product_id
         LEFT JOIN pm_products ru_pm_products ON ru_pm_products.id = carton_labels.ru_labour_product_id
         LEFT JOIN rmt_container_material_owners ON rmt_container_material_owners.id = carton_labels.rmt_container_material_owner_id
         LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_container_material_owners.rmt_container_material_type_id;

       ALTER TABLE public.vw_cartons
        OWNER TO postgres;
    SQL
  end
end
