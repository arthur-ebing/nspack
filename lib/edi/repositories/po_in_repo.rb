# frozen_string_literal: true

module EdiApp
  class PoInRepo < BaseRepo
    def create_pallet(attrs)
      id = DB[:pallets].insert(attrs)
      log_status('pallets', id, 'DEPOT PALLET CREATED FROM PO', user_name: 'System')
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

    def find_standard_pack_code_id(code)
      id = DB[:standard_pack_codes].where(standard_pack_code: code).get(:id)
      return id unless id.nil?

      find_variant_id(:standard_pack_codes, code)
    end

    def find_basic_pack_code_id(standard_pack_code_id)
      DB[:standard_pack_codes].where(id: standard_pack_code_id).get(:basic_pack_code_id)
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

    def find_season_id(date, cultivar_id)
      id = DB[:cultivars].where(id: cultivar_id).get(:commodity_id)
      DB[:seasons]
        .where(commodity_id: id)
        .where(Sequel.lit('start_date <= ?', date))
        .where(Sequel.lit('end_date >= ?', date))
        .get(:id)
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
  end
end
