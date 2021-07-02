# frozen_string_literal: true

module MasterfilesApp
  module FruitFactory # rubocop:disable Metrics/ModuleLength
    def create_grade(opts = {})
      id = get_available_factory_record(:grades, opts)
      return id unless id.nil?

      default = {
        grade_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        rmt_grade: false,
        active: true
      }
      DB[:grades].insert(default.merge(opts))
    end

    def create_treatment_type(opts = {})
      id = get_available_factory_record(:treatment_types, opts)
      return id unless id.nil?

      default = {
        treatment_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:treatment_types].insert(default.merge(opts))
    end

    def create_treatment(opts = {})
      id = get_available_factory_record(:treatments, opts)
      return id unless id.nil?

      treatment_type_id = create_treatment_type

      default = {
        treatment_type_id: treatment_type_id,
        treatment_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:treatments].insert(default.merge(opts))
    end

    def create_inventory_code(opts = {})
      id = get_available_factory_record(:inventory_codes, opts)
      return id unless id.nil?

      default = {
        inventory_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        edi_out_inventory_code: Faker::Lorem.word,
        fruit_item_incentive_rate: Faker::Number.decimal,
        active: true
      }
      DB[:inventory_codes].insert(default.merge(opts))
    end

    def create_basic_pack(opts = {})
      id = get_available_factory_record(:basic_pack_codes, opts)
      return id unless id.nil?

      standard_pack_id = opts.delete(:standard_pack_id)
      default = {
        basic_pack_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        length_mm: Faker::Number.number(digits: 4),
        width_mm: Faker::Number.number(digits: 4),
        height_mm: Faker::Number.number(digits: 4),
        active: true,
        footprint_code: Faker::Lorem.word
      }
      basic_pack_id = DB[:basic_pack_codes].insert(default.merge(opts))
      standard_pack_id ||= create_standard_pack if AppConst::CR_MF.basic_pack_equals_standard_pack?
      DB[:basic_packs_standard_packs].insert(standard_pack_id: standard_pack_id, basic_pack_id: basic_pack_id) if standard_pack_id
      basic_pack_id
    end

    def create_standard_pack(opts = {})
      id = get_available_factory_record(:standard_pack_codes, opts)
      return id unless id.nil?

      default = {
        standard_pack_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        std_pack_label_code: Faker::Lorem.word,
        active: true,
        material_mass: Faker::Number.decimal,
        plant_resource_button_indicator: Faker::Lorem.word,
        use_size_ref_for_edi: false,
        palletizer_incentive_rate: Faker::Number.decimal
      }
      DB[:standard_pack_codes].insert(default.merge(opts))
    end

    def create_std_fruit_size_count(opts = {})
      id = get_available_factory_record(:std_fruit_size_counts, opts)
      return id unless id.nil?

      commodity_id = create_commodity(force_create: true)
      uom_id = create_uom

      default = {
        commodity_id: commodity_id,
        uom_id: uom_id,
        size_count_description: Faker::Lorem.word,
        marketing_size_range_mm: Faker::Lorem.word,
        marketing_weight_range: Faker::Lorem.word,
        size_count_interval_group: Faker::Lorem.word,
        size_count_value: Faker::Number.number(digits: 4),
        minimum_size_mm: Faker::Number.number(digits: 4),
        maximum_size_mm: Faker::Number.number(digits: 4),
        average_size_mm: Faker::Number.number(digits: 4),
        minimum_weight_gm: 1.0,
        maximum_weight_gm: 1.0,
        average_weight_gm: 1.0,
        active: true
      }
      DB[:std_fruit_size_counts].insert(default.merge(opts))
    end

    def create_fruit_actual_counts_for_pack(opts = {})
      id = get_available_factory_record(:fruit_actual_counts_for_packs, opts)
      return id unless id.nil?

      std_fruit_size_count_id = create_std_fruit_size_count
      basic_pack_code_id = create_basic_pack(force_create: true)
      standard_pack_code_ids = create_standard_pack
      size_reference_ids = create_fruit_size_reference

      default = {
        std_fruit_size_count_id: std_fruit_size_count_id,
        basic_pack_code_id: basic_pack_code_id,
        actual_count_for_pack: Faker::Number.number(digits: 4),
        standard_pack_code_ids: BaseRepo.new.array_for_db_col([standard_pack_code_ids]),
        size_reference_ids: BaseRepo.new.array_for_db_col([size_reference_ids]),
        active: true
      }
      DB[:fruit_actual_counts_for_packs].insert(default.merge(opts))
    end

    def create_fruit_size_reference(opts = {})
      id = get_available_factory_record(:fruit_size_references, opts)
      return id unless id.nil?

      default = {
        size_reference: Faker::Lorem.unique.word,
        edi_out_code: Faker::Lorem.word
      }
      DB[:fruit_size_references].insert(default.merge(opts))
    end
  end
end
