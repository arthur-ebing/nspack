Sequel.migration do
  up do
    alter_table(:cartons) do
      drop_foreign_key :production_run_id
      drop_foreign_key :farm_id
      drop_foreign_key :puc_id
      drop_foreign_key :orchard_id
      drop_foreign_key :cultivar_group_id
      drop_foreign_key :cultivar_id
      drop_foreign_key :product_resource_allocation_id
      drop_foreign_key :packhouse_resource_id
      drop_foreign_key :production_line_id
      drop_foreign_key :season_id
      drop_foreign_key :marketing_variety_id
      drop_foreign_key :customer_variety_id
      drop_foreign_key :std_fruit_size_count_id
      drop_foreign_key :basic_pack_code_id
      drop_foreign_key :standard_pack_code_id
      drop_foreign_key :fruit_actual_counts_for_pack_id
      drop_foreign_key :fruit_size_reference_id
      drop_foreign_key :marketing_org_party_role_id
      drop_foreign_key :packed_tm_group_id
      drop_foreign_key :mark_id
      drop_foreign_key :inventory_code_id
      drop_foreign_key :pallet_format_id
      drop_foreign_key :cartons_per_pallet_id
      drop_foreign_key :pm_bom_id
      drop_column :extended_columns
      drop_column :client_size_reference
      drop_column :client_product_code
      drop_column :treatment_ids
      drop_column :marketing_order_number
      drop_foreign_key :fruit_sticker_pm_product_id
      drop_foreign_key :pm_type_id
      drop_foreign_key :pm_subtype_id
      drop_column :sell_by_code
      drop_column :grade_id
      drop_column :product_chars
      drop_column :pallet_label_name
      drop_column :pick_ref
      drop_column :pallet_number
      drop_column :phc
      drop_foreign_key :personnel_identifier_id
      drop_foreign_key :contract_worker_id
      drop_foreign_key :packing_method_id
    end

    run <<~SQL
      DROP TRIGGER cartons_prod_run_stats_queue ON public.cartons;

      CREATE OR REPLACE FUNCTION public.fn_add_run_to_stats_queue_for_carton()
        RETURNS trigger AS
      $BODY$
        DECLARE
          production_run_id INTEGER;
        BEGIN
          EXECUTE 'SELECT production_run_id FROM carton_labels WHERE id = $1 LIMIT 1;' INTO production_run_id USING NEW.carton_label_id;

          IF (production_run_id IS NOT NULL) THEN
            EXECUTE 'INSERT INTO production_run_stats_queue (production_run_id) VALUES($1);' USING production_run_id;
          END IF;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_add_run_to_stats_queue_for_carton()
        OWNER TO postgres;

      CREATE TRIGGER cartons_prod_run_stats_queue
      AFTER INSERT
      ON public.cartons
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_add_run_to_stats_queue_for_carton();
    SQL
  end

  down do
    alter_table(:cartons) do
      add_foreign_key :production_run_id , :production_runs, key: [:id]
      add_foreign_key :farm_id , :farms, key: [:id]
      add_foreign_key :puc_id , :pucs, key: [:id]
      add_foreign_key :orchard_id , :orchards, key: [:id]
      add_foreign_key :cultivar_group_id , :cultivar_groups, key: [:id]
      add_foreign_key :cultivar_id , :cultivars, key: [:id]
      add_foreign_key :product_resource_allocation_id , :product_resource_allocations, key: [:id]
      add_foreign_key :packhouse_resource_id , :plant_resources, key: [:id]
      add_foreign_key :production_line_id , :plant_resources, key: [:id]
      add_foreign_key :season_id , :seasons, key: [:id]
      add_foreign_key :marketing_variety_id , :marketing_varieties, key: [:id]
      add_foreign_key :customer_variety_id , :customer_varieties, key: [:id]
      add_foreign_key :std_fruit_size_count_id , :std_fruit_size_counts, key: [:id]
      add_foreign_key :basic_pack_code_id , :basic_pack_codes, key: [:id]
      add_foreign_key :standard_pack_code_id , :standard_pack_codes, key: [:id]
      add_foreign_key :fruit_actual_counts_for_pack_id , :fruit_actual_counts_for_packs, key: [:id]
      add_foreign_key :fruit_size_reference_id , :fruit_size_references, key: [:id]
      add_foreign_key :marketing_org_party_role_id , :party_roles, key: [:id]
      add_foreign_key :packed_tm_group_id , :target_market_groups, key: [:id]
      add_foreign_key :mark_id , :marks, key: [:id]
      add_foreign_key :inventory_code_id , :inventory_codes, key: [:id]
      add_foreign_key :pallet_format_id , :pallet_formats, key: [:id]
      add_foreign_key :cartons_per_pallet_id , :cartons_per_pallet, key: [:id]
      add_foreign_key :pm_bom_id , :pm_boms, key: [:id]
      add_column :extended_columns, :jsonb
      add_column :client_size_reference, String
      add_column :client_product_code, String
      add_column :treatment_ids , 'integer[]'
      add_column :marketing_order_number, String
      add_foreign_key :fruit_sticker_pm_product_id , :pm_products, key: [:id]
      add_foreign_key :pm_type_id , :pm_types, key: [:id]
      add_foreign_key :pm_subtype_id , :pm_subtypes, key: [:id]
      add_column :sell_by_code, String
      add_foreign_key :grade_id , :grades, key: [:id]
      add_column :product_chars, String
      add_column :pallet_label_name, String
      add_column :pick_ref, String
      add_column :pallet_number, String
      add_column :phc, String
      add_foreign_key :personnel_identifier_id , :personnel_identifiers, key: [:id]
      add_foreign_key :contract_worker_id , :contract_workers, key: [:id]
      add_foreign_key :packing_method_id , :packing_methods, key: [:id]
    end

    run <<~SQL
      DROP TRIGGER cartons_prod_run_stats_queue ON public.cartons;
      DROP FUNCTION public.fn_add_run_to_stats_queue_for_carton();

      CREATE TRIGGER cartons_prod_run_stats_queue
      AFTER INSERT
      ON public.cartons
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_add_run_to_stats_queue();
    SQL
  end
end
