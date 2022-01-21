# frozen_string_literal: true

module EdiApp
  class ProductionRunImport < BaseService
    attr_reader :run_data, :edi_in_repo, :party_repo, :production_run_repo,
                :header, :items, :cultivar_group_id, :commodity_id, :requires_standard_counts

    def initialize(run_data)
      @run_data = run_data
      @edi_in_repo = EdiApp::EdiInRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      @production_run_repo = ProductionApp::ProductionRunRepo.new
    end

    def call
      res = validate_run_data
      return validation_failed_response(res) if res.failure?

      res = validate_item_data
      return validation_failed_response(res) if res.failure?

      lookup_header_ids
      lookup_item_ids
      res = create_run
      return validation_failed_response(res) if res.failure?

      success_response('Run import processed')
    end

    private

    def validate_run_data
      res = NsrunHeaderSchema.call(run_data[:header])
      return res if res.failure?

      @header = res.to_h
    end

    def validate_items
      @requires_standard_counts = commodity_requires_standard_count?
      contract = NsrunContract.new(requires_standard_counts: requires_standard_counts)

      res = nil
      run_data[:items].each do |item|
        res = contract.call(item)
        return res if res.failure?

        @items << res.to_h
      end
      res
    end

    def commodity_requires_standard_count?
      @cultivar_group_id = edi_in_repo.get_id(:cultivar_groups, cultivar_group_code: header[:cultivar_group_code])
      @commodity_id = edi_in_repo.get(:cultivar_groups, :commodity_id, cultivar_group_id)
      edi_in_repo.get(:commodities, :requires_standard_counts, commodity_id)
    end

    def lookup_header_ids # rubocop:disable Metrics/AbcSize
      @template_rec = { template_name: "import_#{header[:run_batch_number]}_#{Time.now.to_i}", cultivar_group_id: cultivar_group_id  }

      @prodrun_rec = { run_batch_number: header[:run_batch_number], cultivar_group_id: cultivar_group_id }
      @prodrun_rec[:farm_id] = edi_in_repo.get_id(:farms, farm_code: header[:farm_code])
      @prodrun_rec[:puc_id] = edi_in_repo.get_id(:pucs, puc_code: header[:puc_code])
      @prodrun_rec[:packhouse_resource_id] = edi_in_repo.get_id(:plant_resources, plant_resource_code: header[:packhouse_code])
      @prodrun_rec[:production_line_id] = edi_in_repo.get_id(:plant_resources, plant_resource_code: header[:line_code])
      @prodrun_rec[:season_id] = edi_in_repo.get_id(:seasons, season_code: header[:season_code])
      @prodrun_rec[:orchard_id] = edi_in_repo.get_id(:orchards, farm_id: @prodrun_rec[:farm_id], orchard_code: header[:orchard_code])
      @prodrun_rec[:season_id] = edi_in_repo.get_id(:seasons, season_code: header[:season_code])
      @prodrun_rec[:cultivar_id] = edi_in_repo.get_id(:cultivars, cultivar_name: header[:cultivar_code]) if header[:cultivar_code]

      #
      #
      #  :customer_variety_id,             # NO
      #  :pm_bom_id,                       # NO
      #  :pallet_label_name,               # NO
      #  :pm_mark_id,                      # NO
      #
      # Sticker         (sticker_pm_product_id)
      # Inner pack spec (inner_pack_pm_product_id)
      #
      # * Label
      # * Tray
      # * Bags
      # * Spec
      # * Remarks (stickers, Kleurkaart 1-7)
      #
    end

    def lookup_item_ids # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      @product_setup_recs = []
      items.each do |item|
        rec = {}
        rec[:basic_pack_code_id] = if AppConst::CR_MF.basic_pack_equals_standard_pack?
                                     edi_in_repo.get_id(:basic_pack_codes, basic_pack_code: item[:standard_pack_code])
                                   else
                                     edi_in_repo.get_id(:basic_pack_codes, basic_pack_code: item[:basic_pack_code])
                                   end
        if requires_standard_counts
          rec[:std_fruit_size_count_id] = edi_repo.get_id(:std_fruit_size_counts, commodity_id: commodity_id, size_count_value: item[:std_fruit_size_count])
          rec[:fruit_actual_counts_for_pack_id] = edi_repo.get_id(:fr, std_fruit_size_count_id: rec[:std_fruit_size_count_id], basic_pack_code_id: rec[:basic_pack_code_id], actual_count_for_pack: actual_count)
        else
          rec[:fruit_size_reference_id] = edi_in_repo.get_id(:fruit_size_references, size_reference: item[:fruit_size_reference])
        end
        rec[:marketing_org_party_role_id] = party_repo.find_party_role_from_org_code_for_role(item[:marketing_org_code], AppConst::ROLE_MARKETER)
        tm_type = edi_in_repo.get_id(:target_market_group_types, target_market_group_type_code: AppConst::PACKED_TM_GROUP)
        rec[:packed_tm_group_id] = edi_in_repo.get_id(:target_market_groups, target_market_group_type_id: tm_type, target_market_group_name: item[:packed_tm_group])
        pallet_base_id = edi_in_repo.get_id(:pallet_bases, pallet_base_code: item[:pallet_base])
        pallet_stack_type_id = edi_in_repo.get_id(:pallet_stack_types, stack_type_code: item[:pallet_stack_type])
        rec[:pallet_format_id] = edi_in_repo.get_id(:pallet_formats, pallet_base_id: pallet_base_id, pallet_stack_type_id: pallet_stack_type_id)
        rec[:cartons_per_pallet_id] = edi_in_repo.get_id(:cartons_per_pallet, pallet_format_id: rec[:pallet_format_id], basic_pack_id: rec[:basic_pack_code_id])
        cpp = edi_in_repo.get(:cartons_per_pallet, :cartons_per_pallet, rec[:cartons_per_pallet_id])
        raise Crossbeams::InfoError, "Cartons per pallet do not match - #{cpp} : #{item[:cartons_per_pallet]}" if cpp && cpp != item[:cartons_per_pallet]

        #  :cartons_per_pallet_id,           # | Crtns/Pal (validate against basic pack & format)
        rec[:treatment_ids] = item[:treatment_ids].split(',').map(&:strip) unless item[:treatment_ids].nil?
        rec[:target_customer_party_role_id] = party_repo.find_party_role_from_org_code_for_role(item[:target_customer_code], AppConst::ROLE_TARGET_CUSTOMER) unless item[:target_customer_code].nil?
        rec[:rebin] = true if item[:rebin] == 'Y'

        # rec[:marketing_variety_id] = edi_in_repo.get_id(:marketing_varieties, marketing_variety_code: item[:marketing_variety])
        # rec[:standard_pack_code_id] = edi_in_repo.get_id(:standard_pack_codes, standard_pack_code: item[:standard_pack_code])
        # rec[:mark_id] = edi_in_repo.get_id(:marks, mark_code: item[:mark_code])
        # rec[:inventory_code_id] = edi_in_repo.get_id(:inventory_codes, inventory_code: item[:inventory_code])
        # rec[:grade_id] = edi_in_repo.get_id(:grades, grade_code: item[:grade_code])
        # rec[:product_chars] = item[:product_chars] unless item[:product_chars].nil?
        # rec[:target_market_id] = edi_in_repo.get_id(:target_markets, target_market_name: item[:target_market_code])
        # rec[:gtin_code] = item[:gtin_code] unless item[:gtin_code].nil?
        # rec[:rmt_class_id] = edi_in_repo.get_id(:rmt_classes, rmt_class_code: item[:rmt_class_code]) unless item[:rmt_class_code].nil?
        # rec[:client_size_reference] = item[:client_size_reference] unless item[:client_size_reference].nil?
        # rec[:client_product_code] = item[:client_product_code] unless item[:client_product_code].nil?
        # rec[:marketing_order_number] = item[:marketing_order_number] unless item[:marketing_order_number].nil?
        # rec[:sell_by_code] = item[:sell_by_code] unless item[:sell_by_code].nil?
        # rec[:colour_percentage_id] = edi_in_repo.get_id(:colour_percentages, colour_percentage_code: item[:colour_percentage_code]) unless item[:colour_percentage_code].nil?
        # rec[:carton_label_template_id] = edi_in_repo.get_id(:label_templates, label_template_name: item[:carton_label_template]) unless item[:carton_label_template].nil?
        # rec[:rmt_code_id] = edi_in_repo.get_id(:rmt_codes, rmt_code: item[:rmt_code]) if item[:rmt_code]
        # rec[:rmt_size_id] = edi_in_repo.get_id(:rmt_sizes, rmt_size_code: item[:rmt_size_code]) if item[:rmt_size_code]

        do_bulk_lookup_and_copy(rec, item)

        @product_setup_recs << rec
      end
    end
    #  DETAIL:
    #  :marketing_variety_id,            # var code | Variety
    #  :std_fruit_size_count_id,         # std count (OPT - commodity says "required" - if true, std + actual required otherwise just size ref)
    #  :basic_pack_code_id,              # (OPT but validate is basic != std)
    #  :standard_pack_code_id,           # | M12T
    #  :fruit_actual_counts_for_pack_id, # | (Validate against commod + basic => actual)
    #  :fruit_size_reference_id,         # (OPT, but must be there if commod says not required)

    #  :marketing_org_party_role_id,     # org_code | Org
    #  :packed_tm_group_id,              # | Packed TM Group
    #  :mark_id,                         # | Mark
    #  :inventory_code_id,               # | Inv
    #  :pallet_format_id,                # | Pal base + stack type
    #  :cartons_per_pallet_id,           # | Crtns/Pal (validate against basic pack & format)
    #  :client_size_reference,           # (OPT)
    #  :client_product_code,             # (OPT)
    #  :treatment_ids,                   # (OPT - pass ids, not codes & validate)
    #  :marketing_order_number,          # (OPT)
    #  :sell_by_code,                    # (OPT)
    #  :grade_id,                        # | Grade
    #  :product_chars,                   # (OPT)
    #  :target_market_id,                # TM
    #  :gtin_code,                       # If provided & std count provided - mark, grade, inv etc can be blank... else they must be there
    #  :rmt_class_id,                    # (OPT)
    #  :target_customer_party_role_id,   # (OPT)
    #  :colour_percentage_id,            # (OPT)
    #  :carton_label_template_id,        # (OPT)
    #  :rebin,                           # (OPT, default false)
    def create_run # rubocop:disable Metrics/AbcSize
      # res = ProductionApp::ProductionRunNewContract.new.call(header)
      # return res if res.failure?
      #
      # items.each do |item|
      #   res = ProductionApp::PRoductSetupSchema.call(item)
      # end
      production_run_repo.transaction do
        template_id = production_run_repo.create(:product_setup_templates, template_rec)
        log_status(:product_setup_templates, template_id, 'IMPORTED')

        id = production_run_repo.create_production_run(prodrun_rec.merge(product_setup_template_id: template_id))
        production_run_repo.create_production_run_stats(id)
        production_run_repo.log_status(:production_runs, id, 'IMPORTED')

        product_setup_recs.each do |setup|
          setup_id = production_run_repo.create(:product_setups, setup.merge(product_setup_template_id: template_id))
          log_status(:product_setups, setup_id, 'IMPORTED')
        end
        # log_transaction
      end
      ok_response
    end

    def do_bulk_lookup_and_copy(rec, item)
      quick_lkps = {
        marketing_variety_id: { table: :marketing_varieties, col: :marketing_variety_code, item_key: :marketing_variety },
        standard_pack_code_id: { table: :standard_pack_codes, col: :standard_pack_code, item_key: :standard_pack_code },
        mark_id: { table: :marks, col: :mark_code, item_key: :mark_code },
        inventory_code_id: { table: :inventory_codes, col: :inventory_code, item_key: :inventory_code },
        grade_id: { table: :grades, col: :grade_code, item_key: :grade_code },
        target_market_id: { table: :target_markets, col: :target_market_name, item_key: :target_market_code },
        rmt_class_id: { table: :rmt_classes, col: :rmt_class_code, item_key: :rmt_class_code, optional: true },
        colour_percentage_id: { table: :colour_percentages, col: :colour_percentage_code, item_key: :colour_percentage_code, optional: true },
        carton_label_template_id: { table: :label_templates, col: :label_template_name, item_key: :carton_label_template, optional: true },
        rmt_code_id: { table: :rmt_codes, col: :rmt_code, item_key: :rmt_code, optional: true },
        rmt_size_id: { table: :rmt_sizes, col: :rmt_size_code, item_key: :rmt_size_code, optional: true }
      }
      quick_lkps.each do |k, v|
        lookup_id(rec, item, k, v[:table], v[:col], v[:item_key], optional: v[:optional])
      end
      quick_copies = {
        product_chars: { item_key: :product_chars, optional: true },
        gtin_code: { item_key: :gtin_code, optional: true },
        client_size_reference: { item_key: :client_size_reference, optional: true },
        client_product_code: { item_key: :client_product_code, optional: true },
        marketing_order_number: { item_key: :marketing_order_number, optional: true },
        sell_by_code: { item_key: :sell_by_code, optional: true }
      }
      quick_copies.each do |k, v|
        copy_over_value(rec, item, k, v[:item_key], optional: v[:optional])
      end
    end

    def lookup_id(rec, item, rec_key, table, col, item_key, optional: false)
      rec[rec_key] = if optional
                       item[item_key].nil? ? nil : edi_in_repo.get_id(table, col => item[item_key])
                     else
                       edi_in_repo.get_id(table, col => item[item_key])
                     end
    end

    def copy_over_value(rec, item, rec_key, item_key, optional: false)
      rec[rec_key] = if optional && item[item_key].nil?
                       nil
                     else
                       item[item_key]
                     end
    end
  end
end
