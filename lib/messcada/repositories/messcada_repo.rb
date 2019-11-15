# frozen_string_literal: true

module MesscadaApp
  class MesscadaRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    crud_calls_for :carton_labels, name: :carton_label, wrapper: CartonLabel
    crud_calls_for :cartons, name: :carton, wrapper: Carton
    crud_calls_for :pallets, name: :pallet, wrapper: Pallet
    crud_calls_for :pallet_sequences, name: :pallet_sequence, wrapper: PalletSequence

    def carton_label_exists?(carton_label_id)
      exists?(:carton_labels, id: carton_label_id)
    end

    def carton_label_carton_exists?(carton_label_id)
      exists?(:cartons, carton_label_id: carton_label_id)
    end

    def carton_exists?(carton_id)
      exists?(:cartons, id: carton_id)
    end

    def carton_label_carton_id(carton_label_id)
      DB[:cartons].where(carton_label_id: carton_label_id).get(:id)
    end

    def resource_code_exists?(resource_code)
      exists?(:system_resources, system_resource_code: resource_code)
    end

    def production_run_exists?(production_run_id)
      exists?(:production_runs, id: production_run_id)
    end

    def standard_pack_code_exists?(plant_resource_button_indicator)
      exists?(:standard_pack_codes, plant_resource_button_indicator: plant_resource_button_indicator)
    end

    def one_standard_pack_code?(plant_resource_button_indicator)
      DB[:standard_pack_codes].where(plant_resource_button_indicator: plant_resource_button_indicator).count == 1
    end

    def find_standard_pack_code(plant_resource_button_indicator)
      DB[:standard_pack_codes].where(plant_resource_button_indicator: plant_resource_button_indicator).get(:id)
    end

    def find_standard_pack_code_material_mass(id)
      DB[:standard_pack_codes].where(id: id).get(:material_mass)
    end

    def find_pallet_from_carton(carton_id)
      DB[:pallet_sequences].where(scanned_from_carton_id: carton_id).get(:pallet_id)
    end

    def find_resource_location_id(id)
      DB[:plant_resources].where(id: id).get(:location_id)
    end

    def find_resource_phc(id)
      # DB[:plant_resources].where(id: id).select(:id, Sequel.lit("resource_properties ->> 'phc'").as(:phc)).first[:phc].to_s
      DB[:plant_resources].where(id: id).get(Sequel.lit("resource_properties ->> 'phc'"))
    end

    def find_resource_packhouse_no(id)
      # DB[:plant_resources].where(id: id).select(:id, Sequel.lit("resource_properties ->> 'packhouse_no'").as(:packhouse_no)).first[:packhouse_no].to_s
      DB[:plant_resources].where(id: id).get(Sequel.lit("resource_properties ->> 'packhouse_no'"))
    end

    def find_cartons_per_pallet(id)
      DB[:cartons_per_pallet].where(id: id).get(:cartons_per_pallet)
    end

    # Create several carton_labels records returning an array of the newly-created ids
    def create_carton_labels(no_of_prints, attrs)
      DB[:carton_labels].multi_insert(no_of_prints.to_i.times.map { attrs.merge(carton_equals_pallet: AppConst::CARTON_EQUALS_PALLET) }, return: :primary_key)
    end

    def carton_label_pallet_number(carton_label_id)
      return nil unless AppConst::CARTON_EQUALS_PALLET

      DB[:carton_labels].where(id: carton_label_id).get(:pallet_number)
    end

    def create_pallet(pallet)
      id = DB[:pallets].insert(pallet)
      log_status('pallets', id, AppConst::PALLETIZED_NEW_PALLET)

      id
    end

    def create_sequences(pallet_sequence, pallet_id)
      pallet_sequence = pallet_sequence.merge(pallet_params(pallet_id))
      DB[:pallet_sequences].insert(pallet_sequence)
    end

    # def create_pallet_and_sequences(pallet, pallet_sequence)
    #   id = DB[:pallets].insert(pallet)
    #
    #   pallet_sequence = pallet_sequence.merge(pallet_params(id))
    #   DB[:pallet_sequences].insert(pallet_sequence)
    #
    #   log_status('pallets', id, AppConst::PALLETIZED_NEW_PALLET)
    #   # ProductionApp::RunStatsUpdateJob.enqueue(production_run_id, 'PALLET_CREATED')
    #
    #   { success: true }
    # end

    def pallet_params(pallet_id)
      {
        pallet_id: pallet_id,
        pallet_number: find_pallet_number(pallet_id)
      }
    end

    def find_pallet_number(id)
      DB[:pallets].where(id: id).get(:pallet_number)
    end

    # def find_rmt_container_type_tare_weight(rmt_container_type_id)
    #   DB[:rmt_container_types].where(id: rmt_container_type_id).map { |o| o[:tare_weight] }.first
    # end
    #
    def get_rmt_bin_setup_reqs(bin_id)
      DB[<<~SQL, bin_id].first
        SELECT b.id, b.farm_id, b.orchard_id, b.cultivar_id
        ,c.cultivar_name, c.cultivar_group_id, cg.cultivar_group_code,f.farm_code, o.orchard_code
        FROM rmt_bins b
        JOIN cultivars c ON c.id=b.cultivar_id
        JOIN cultivar_groups cg ON cg.id=c.cultivar_group_id
        JOIN farms f ON f.id=b.farm_id
        JOIN orchards o ON o.id=b.orchard_id
        WHERE b.id = ?
      SQL
    end

    def get_run_setup_reqs(run_id)
      ProductionApp::ProductionRunRepo.new.find_production_run_flat(run_id).to_h
      # DB["select r.id, r.farm_id, r.orchard_id, r.cultivar_group_id, r.cultivar_id, r.allow_cultivar_mixing, r.allow_orchard_mixing
      #   ,c.cultivar_name, cg.cultivar_group_code,f.farm_code, o.orchard_code, p.puc_code
      #   from production_runs r
      #   left join cultivars c on c.id=r.cultivar_id
      #   join cultivar_groups cg on cg.id=r.cultivar_group_id
      #   join farms f on f.id=r.farm_id
      #   join orchards o on o.id=r.orchard_id
      #   join pucs p on p.id=r.puc_id
      #   WHERE r.id = ?", run_id].first
    end

    def get_pallet_by_carton_label_id(carton_label_id)
      pallet = DB["select p.pallet_number
          from pallets p
          join pallet_sequences ps on p.id = ps.pallet_id
          join cartons c on c.id = ps.scanned_from_carton_id
          join carton_labels cl on cl.id = c.carton_label_id
          where cl.id = ?", carton_label_id].first
      return pallet[:pallet_number] unless pallet.nil?
    end

    def production_run_stats(run_id)
      DB[:production_run_stats].where(production_run_id: run_id).map { |p| p[:bins_tipped] }.first
    end

    def find_pallet_sequences_by_pallet_number(pallet_number)
      # DB[:vw_pallet_sequence_flat].where(pallet_number: pallet_number)
      DB["SELECT *
          FROM vw_pallet_sequence_flat
          WHERE pallet_number = '#{pallet_number}'
          order by pallet_sequence_number asc"]
    end

    def find_pallet_sequences_from_same_pallet(id)
      DB["select sis.id
          from pallet_sequences s
          join pallet_sequences sis on sis.pallet_id=s.pallet_id
          where s.id = #{id}
          order by sis.pallet_sequence_number asc"].map { |s| s[:id] }
    end

    def find_pallet_sequence_attrs(id)
      DB["SELECT *
          FROM vw_pallet_sequence_flat
          WHERE id = ?", id].first
    end

    def update_pallet_sequence_verification_result(pallet_sequence_id, params)
      nett_weight_upd = ", nett_weight=#{params[:nett_weight]} " if params[:nett_weight]
      upd = "UPDATE pallet_sequences SET verified=true,verified_at='#{Time.now}',verification_result = '#{params[:verification_result]}', verification_passed=#{params[:verification_result] != 'failed'}, pallet_verification_failure_reason_id = #{(params[:verification_result] != 'failed' ? 'Null' : "'#{params[:verification_failure_reason]}'")} #{nett_weight_upd} WHERE id = #{pallet_sequence_id};"
      DB[upd].update
    end

    def update_pallet_nett_weight(pallet_id)
      DB["UPDATE pallets p set nett_weight=(select sum(nett_weight) from pallet_sequences where pallet_id=p.id) WHERE id = #{pallet_id};"].update
    end

    def pallet_verified?(pallet_id)
      DB["select * from pallet_sequences where pallet_id = '#{pallet_id}' AND (verified is null or verified is false) "].first.nil?
    end

    # instance of a carton label with all its relevant lookup columns
    def carton_label_printing_instance(id)
      query = <<~SQL
        SELECT "carton_labels"."id" AS carton_label_id,
        "carton_labels"."production_run_id",
        "packhouses"."plant_resource_code" AS packhouse,
        "lines"."plant_resource_code" AS line,
        "carton_labels"."label_name",
        "farms"."farm_code",
        "pucs"."puc_code",
        "orchards"."orchard_code",
        "commodities"."code" AS commodity,
        "cultivar_groups"."cultivar_group_code",
        "cultivars"."cultivar_name",
        "marketing_varieties"."marketing_variety_code",
        "marketing_varieties"."description" AS marketing_variety_description,
        "cvv"."marketing_variety_code" AS customer_variety_code,
        "std_fruit_size_counts"."size_count_value",
        "fruit_size_references"."size_reference",
        "fruit_actual_counts_for_packs"."actual_count_for_pack",
        "basic_pack_codes"."basic_pack_code",
        "standard_pack_codes"."standard_pack_code",
        fn_party_role_name("carton_labels"."marketing_org_party_role_id") AS marketer,
        "marks"."mark_code",
        "inventory_codes"."inventory_code",
        "product_setup_templates"."template_name",
        "pm_boms"."bom_code",
        (SELECT array_agg("clt"."treatment_code")
          FROM (SELECT "t"."treatment_code"
          FROM "treatments" t
          JOIN "carton_labels" cl ON "t"."id" = ANY("cl"."treatment_ids")
          WHERE "cl"."id" = "carton_labels"."id"
          ORDER BY "t"."treatment_code" DESC) clt) AS treatments,
        "carton_labels"."client_size_reference",
        "carton_labels"."client_product_code",
        "carton_labels"."marketing_order_number",
        "target_market_groups"."target_market_group_name" AS packed_tm_group,
        "seasons"."season_code",
        "pm_subtypes"."subtype_code",
        "pm_types"."pm_type_code",
        "cartons_per_pallet"."cartons_per_pallet",
        "pm_products"."product_code",
        "carton_labels"."pallet_number",
        "carton_labels"."sell_by_code",
        "grades"."grade_code",
        "carton_labels"."product_chars",
        "carton_labels"."pick_ref",
        "carton_labels"."phc"
        FROM "carton_labels"
        JOIN "production_runs" ON "production_runs"."id" = "carton_labels"."production_run_id"
        LEFT JOIN "product_resource_allocations" ON "product_resource_allocations"."id" = "carton_labels"."product_resource_allocation_id"
        LEFT JOIN "product_setups" ON "product_setups"."id" = "product_resource_allocations"."product_setup_id"
        LEFT JOIN "product_setup_templates" ON "product_setup_templates"."id" = "product_setups"."product_setup_template_id"
        JOIN "plant_resources" packhouses ON "packhouses"."id" = "carton_labels"."packhouse_resource_id"
        JOIN "plant_resources" lines ON "lines"."id" = "carton_labels"."production_line_id"
        JOIN "farms" ON "farms"."id" = "carton_labels"."farm_id"
        JOIN "pucs" ON "pucs"."id" = "carton_labels"."puc_id"
        JOIN "orchards" ON "orchards"."id" = "carton_labels"."orchard_id"
        JOIN "cultivar_groups" ON "cultivar_groups"."id" = "carton_labels"."cultivar_group_id"
        LEFT JOIN "grades" ON "grades"."id" = "carton_labels"."grade_id"
        LEFT JOIN "cultivars" ON "cultivars"."id" = "carton_labels"."cultivar_id"
        LEFT JOIN "commodities" ON "commodities"."id" = "cultivars"."commodity_id"
        JOIN "marketing_varieties" ON "marketing_varieties"."id" = "carton_labels"."marketing_variety_id"
        LEFT JOIN "customer_variety_varieties" ON "customer_variety_varieties"."id" = "carton_labels"."customer_variety_variety_id"
        LEFT JOIN "marketing_varieties" cvv ON "cvv"."id" = "customer_variety_varieties"."marketing_variety_id"
        LEFT JOIN "std_fruit_size_counts" ON "std_fruit_size_counts"."id" = "carton_labels"."std_fruit_size_count_id"
        LEFT JOIN "fruit_size_references" ON "fruit_size_references"."id" = "carton_labels"."fruit_size_reference_id"
        LEFT JOIN "fruit_actual_counts_for_packs" ON "fruit_actual_counts_for_packs"."id" = "carton_labels"."fruit_actual_counts_for_pack_id"
        JOIN "basic_pack_codes" ON "basic_pack_codes"."id" = "carton_labels"."basic_pack_code_id"
        JOIN "standard_pack_codes" ON "standard_pack_codes"."id" = "carton_labels"."standard_pack_code_id"
        JOIN "marks" ON "marks"."id" = "carton_labels"."mark_id"
        JOIN "inventory_codes" ON "inventory_codes"."id" = "carton_labels"."inventory_code_id"
        LEFT JOIN "pm_boms" ON "pm_boms"."id" = "carton_labels"."pm_bom_id"
        LEFT JOIN "pm_subtypes" ON "pm_subtypes"."id" = "carton_labels"."pm_subtype_id"
        LEFT JOIN "pm_types" ON "pm_types"."id" = "carton_labels"."pm_type_id"
        JOIN "target_market_groups" ON "target_market_groups"."id" = "carton_labels"."packed_tm_group_id"
        JOIN "seasons" ON "seasons"."id" = "carton_labels"."season_id"
        JOIN "cartons_per_pallet" ON "cartons_per_pallet"."id" = "carton_labels"."cartons_per_pallet_id"
        LEFT JOIN "pm_products" ON "pm_products"."id" = "carton_labels"."fruit_sticker_pm_product_id"
        JOIN "pallet_formats" ON "pallet_formats"."id" = "carton_labels"."pallet_format_id"
        WHERE "carton_labels"."id" = ?
      SQL
      DB[query, id].first
    end

    # instance of an allocated product setup with all its relevant lookup columns
    def allocated_product_setup_label_printing_instance(id)
      query = <<~SQL
        SELECT "product_setups"."id" AS carton_label_id,
        "product_resource_allocations"."production_run_id",
        "packhouses"."plant_resource_code" AS packhouse,
        "lines"."plant_resource_code" AS line,
        "label_templates"."label_template_name" AS label_name,
        "farms"."farm_code",
        "pucs"."puc_code",
        "orchards"."orchard_code",
        "commodities"."code" AS commodity,
        "cultivar_groups"."cultivar_group_code",
        "cultivars"."cultivar_name",
        "marketing_varieties"."marketing_variety_code",
        "cvv"."marketing_variety_code" AS customer_variety_code,
        "std_fruit_size_counts"."size_count_value",
        "fruit_size_references"."size_reference",
        "fruit_actual_counts_for_packs"."actual_count_for_pack",
        "basic_pack_codes"."basic_pack_code",
        "standard_pack_codes"."standard_pack_code",
        fn_party_role_name("product_setups"."marketing_org_party_role_id") AS marketer,
        "marks"."mark_code",
        "inventory_codes"."inventory_code",
        "product_setup_templates"."template_name",
        "pm_boms"."bom_code",
        (SELECT array_agg("clt"."treatment_code")
          FROM (SELECT "t"."treatment_code"
          FROM "treatments" t
          JOIN "product_setups" cl ON "t"."id" = ANY("cl"."treatment_ids")
          WHERE "cl"."id" = "product_setups"."id"
          ORDER BY "t"."treatment_code" DESC) clt) AS treatments,
        "product_setups"."client_size_reference",
        "product_setups"."client_product_code",
        "product_setups"."marketing_order_number",
        "target_market_groups"."target_market_group_name" AS packed_tm_group,
        "seasons"."season_code",
        'UNK' AS subtype_code,
        'UNK' AS pm_type_code,
        -- "pm_subtypes"."subtype_code",
        -- "pm_types"."pm_type_code",
        "cartons_per_pallet"."cartons_per_pallet",
        'UNKNOWN' AS product_code
        -- "pm_products"."product_code"
        FROM "product_resource_allocations"
        JOIN "production_runs" ON "production_runs"."id" = "product_resource_allocations"."production_run_id"
        -- LEFT JOIN "product_resource_allocations" ON "product_resource_allocations"."id" = "carton_labels"."product_resource_allocation_id"
        JOIN "product_setups" ON "product_setups"."id" = "product_resource_allocations"."product_setup_id"
        JOIN "product_setup_templates" ON "product_setup_templates"."id" = "product_setups"."product_setup_template_id"
        JOIN "plant_resources" packhouses ON "packhouses"."id" = "production_runs"."packhouse_resource_id"
        JOIN "plant_resources" lines ON "lines"."id" = "production_runs"."production_line_id"
        LEFT JOIN "label_templates" ON "label_templates"."id" = "product_resource_allocations"."label_template_id"
        JOIN "farms" ON "farms"."id" = "production_runs"."farm_id"
        JOIN "pucs" ON "pucs"."id" = "production_runs"."puc_id"
        JOIN "orchards" ON "orchards"."id" = "production_runs"."orchard_id"
        JOIN "cultivar_groups" ON "cultivar_groups"."id" = "production_runs"."cultivar_group_id"
        LEFT JOIN "cultivars" ON "cultivars"."id" = "production_runs"."cultivar_id"
        LEFT JOIN "commodities" ON "commodities"."id" = "cultivars"."commodity_id"
        JOIN "marketing_varieties" ON "marketing_varieties"."id" = "product_setups"."marketing_variety_id"
        LEFT JOIN "customer_variety_varieties" ON "customer_variety_varieties"."id" = "product_setups"."customer_variety_variety_id"
        LEFT JOIN "marketing_varieties" cvv ON "cvv"."id" = "customer_variety_varieties"."marketing_variety_id"
        LEFT JOIN "std_fruit_size_counts" ON "std_fruit_size_counts"."id" = "product_setups"."std_fruit_size_count_id"
        LEFT JOIN "fruit_size_references" ON "fruit_size_references"."id" = "product_setups"."fruit_size_reference_id"
        LEFT JOIN "fruit_actual_counts_for_packs" ON "fruit_actual_counts_for_packs"."id" = "product_setups"."fruit_actual_counts_for_pack_id"
        JOIN "basic_pack_codes" ON "basic_pack_codes"."id" = "product_setups"."basic_pack_code_id"
        JOIN "standard_pack_codes" ON "standard_pack_codes"."id" = "product_setups"."standard_pack_code_id"
        JOIN "marks" ON "marks"."id" = "product_setups"."mark_id"
        JOIN "inventory_codes" ON "inventory_codes"."id" = "product_setups"."inventory_code_id"
        LEFT JOIN "pm_boms" ON "pm_boms"."id" = "product_setups"."pm_bom_id"
        -- LEFT JOIN "pm_subtypes" ON "pm_subtypes"."id" = "product_setups"."pm_subtype_id"
        -- LEFT JOIN "pm_types" ON "pm_types"."id" = "pm_subtypes"."pm_type_id"
        JOIN "target_market_groups" ON "target_market_groups"."id" = "product_setups"."packed_tm_group_id"
        JOIN "seasons" ON "seasons"."id" = "production_runs"."season_id"
        JOIN "cartons_per_pallet" ON "cartons_per_pallet"."id" = "product_setups"."cartons_per_pallet_id"
        -- LEFT JOIN "pm_products" ON "pm_products"."id" = "product_setups"."fruit_sticker_pm_product_id"
        JOIN "pallet_formats" ON "pallet_formats"."id" = "product_setups"."pallet_format_id"
        WHERE "product_resource_allocations"."id" = ?
      SQL
      DB[query, id].first
    end
  end
end
