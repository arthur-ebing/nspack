# frozen_string_literal: true

module EdiApp
  class PoInRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    def create_pallet(attrs)
      id = DB[:pallets].insert(attrs)
      log_status(:pallets, id, 'DEPOT PALLET CREATED FROM PO', user_name: 'System')
      id
    end

    def create_pallet_sequence(attrs)
      DB[:pallet_sequences].insert(attrs)
    end

    def find_pallet_format_and_cpp_id(base_type, tot_cartons, basic_pack_id)
      pallet_base_id = DB[:pallet_bases].where(pallet_base_code: base_type).or(edi_in_pallet_base: base_type).get(:id)
      return [nil, nil] if pallet_base_id.nil?

      DB[:cartons_per_pallet]
        .join(:pallet_formats, id: :pallet_format_id)
        .where(basic_pack_id: basic_pack_id, cartons_per_pallet: tot_cartons)
        .where(pallet_base_id: pallet_base_id)
        .get([:pallet_format_id, Sequel[:cartons_per_pallet][:id]])
    end

    def find_standard_pack_id(code)
      id = DB[:standard_pack_codes].where(standard_pack_code: code).get(:id)
      return id unless id.nil?

      find_variant_id(:standard_pack_codes, code)
    end

    def find_basic_pack_id(standard_pack_code_id)
      DB[:basic_packs_standard_packs].where(standard_pack_id: standard_pack_code_id).get(:basic_pack_id)
    end

    def find_puc_id(code)
      id = DB[:pucs].where(puc_code: code).get(:id)
      return id unless id.nil?

      find_variant_id(:pucs, code)
    end

    def find_farm_id(puc_id)
      return nil if puc_id.nil?

      DB[:farms_pucs].where(puc_id: puc_id).select_map(:farm_id).first
    end

    def find_orchard_id(farm_id, orchard)
      return nil if farm_id.nil?

      DB[:orchards].where(farm_id: farm_id, orchard_code: orchard).get(:id)
    end

    def find_variant_id(table_name, code)
      DB[:masterfile_variants].where(masterfile_table: table_name.to_s, variant_code: code).get(:masterfile_id)
    end

    def find_marketing_variety_id(code)
      id = DB[:marketing_varieties].where(marketing_variety_code: code).get(:id)
      return id unless id.nil?

      find_variant_id(:marketing_varieties, code)
    end

    def find_cultivar_id_from_mkv(marketing_variety_id)
      return nil if marketing_variety_id.nil?

      DB[:marketing_varieties_for_cultivars].where(marketing_variety_id: marketing_variety_id).get(:cultivar_id)
    end

    def find_cultivar_group_id(cultivar_id)
      DB[:cultivars].where(id: cultivar_id).get(:cultivar_group_id)
    end

    def find_fruit_size_reference_id(code)
      id = DB[:fruit_size_references].where(size_reference: code).or(edi_out_code: code).get(:id)
      return id unless id.nil?

      find_variant_id(:fruit_size_references, code)
    end

    def find_mark_id(code)
      id = DB[:marks].where(mark_code: code).get(:id)
      return id unless id.nil?

      find_variant_id(:marks, code)
    end

    def find_inventory_code_id(code)
      id = DB[:inventory_codes].where(inventory_code: code).get(:id)
      return id unless id.nil?

      find_variant_id(:inventory_codes, code)
    end

    def find_grade_id(code)
      id = DB[:grades].where(grade_code: code).get(:id)
      return id unless id.nil?

      find_variant_id(:grades, code)
    end

    def find_packed_tm_group_id(code)
      id = DB[:target_market_groups]
           .where(target_market_group_type_id: DB[:target_market_group_types].where(target_market_group_type_code: AppConst::PACKED_TM_GROUP).get(:id))
           .where(target_market_group_name: code)
           .get(:id)
      return id unless id.nil?

      find_variant_id(:packed_tm_group, code)
    end

    def find_target_market_id(code)
      id = DB[:target_markets]
           .where(target_market_name: code)
           .get(:id)
      return id unless id.nil?

      find_variant_id(:target_market, code)
    end

    # Use region, country and target_market of incoming PO to map to packed_tm_group, target_market and target_customer, as follows:
    # packed_tm_group:
    #
    #     Find a packed_tm_group where po.region is a destination_region that is associated with such packed_tm_group
    #     if not found or > 1 records: try a direct lookup of packed_tm_group = po.target_market or a variant thereof
    #
    # target_market
    #
    #     Find a target_market where po.country is a destination_country or variant thereof
    #     if not found or > 1 records: try a direct lookup of target_market = po.target_market or a variant thereof
    #
    # target_customer (optional)
    #
    #     If po.target_market is neither a packed_tm_group or a target_market, try a lookup of po.target_market = target_customer or variant thereof
    def find_targets(target_market, target_region, target_country) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      if target_region.nil? && target_country.nil?
        return success_response('ok', single: true,
                                      check_customer: false,
                                      packed_tm_group_id: find_packed_tm_group_id(target_market),
                                      target_market_id: nil)
      end

      packed_tm_group_id = nil
      target_market_id = nil

      region_id = DB[:destination_regions].where(destination_region_name: target_region).get(:id)
      tm_group_ids = DB[:destination_regions_tm_groups].where(destination_region_id: region_id).select_map(:target_market_group_id)
      packed_tm_group_id = tm_group_ids.first if tm_group_ids.length == 1
      packed_tm_group_id = find_packed_tm_group_id(target_market) if packed_tm_group_id.nil?

      country_id = DB[:destination_countries].where(iso_country_code: target_country).get(:id)
      tm_ids = DB[:target_markets_for_countries].where(destination_country_id: country_id).select_map(:target_market_id)
      target_market_id = tm_ids.first if tm_ids.length == 1
      target_market_id = find_target_market_id(target_market) if target_market_id.nil?

      check_customer = false
      if packed_tm_group_id && target_market_id
        tmg_code = get(:target_market_groups, packed_tm_group_id, :target_market_group_name)
        tm_code = get(:target_markets, target_market_id, :target_market_name)
        check_customer = true unless target_market == tmg_code || target_market == tm_code
      end

      success_response('ok', single: false,
                             check_customer: check_customer,
                             packed_tm_group_id: packed_tm_group_id,
                             target_market_id: target_market_id)
    end
  end
end
