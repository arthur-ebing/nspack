# frozen_string_literal: true

module MasterfilesApp
  module FruitFactory # rubocop:disable Metrics/ModuleLength
    def create_grade(opts = {})
      default = {
        grade_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        rmt_grade: false,
        active: true
      }
      DB[:grades].insert(default.merge(opts))
    end

    def create_treatment_type(opts = {})
      default = {
        treatment_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:treatment_types].insert(default.merge(opts))
    end

    def create_treatment(opts = {})
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
      default = {
        inventory_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        edi_out_inventory_code: Faker::Lorem.word,
        fruit_item_incentive_rate: Faker::Number.decimal,
        active: true
      }
      DB[:inventory_codes].insert(default.merge(opts))
    end

    def create_basic_pack_code(opts = {})
      default = {
        basic_pack_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        length_mm: Faker::Number.number(digits: 4),
        width_mm: Faker::Number.number(digits: 4),
        height_mm: Faker::Number.number(digits: 4),
        active: true
      }
      DB[:basic_pack_codes].insert(default.merge(opts))
    end

    def create_standard_pack_code(opts = {})
      basic_pack_code_id = create_basic_pack_code
      default = {
        standard_pack_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        std_pack_label_code: Faker::Lorem.word,
        active: true,
        material_mass: Faker::Number.decimal,
        plant_resource_button_indicator: Faker::Lorem.word,
        basic_pack_code_id: basic_pack_code_id,
        use_size_ref_for_edi: false,
        palletizer_incentive_rate: Faker::Number.decimal
      }
      DB[:standard_pack_codes].insert(default.merge(opts))
    end

    def create_std_fruit_size_count(opts = {})
      commodity_id = create_commodity
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
      std_fruit_size_count_id = create_std_fruit_size_count
      basic_pack_code_id = create_basic_pack_code
      standard_pack_code_ids = create_standard_pack_code
      size_reference_ids = create_fruit_size_reference

      default = {
        std_fruit_size_count_id: std_fruit_size_count_id,
        basic_pack_code_id: basic_pack_code_id,
        actual_count_for_pack: Faker::Number.number(digits: 4),
        standard_pack_code_ids: "{#{standard_pack_code_ids}}",
        size_reference_ids: "{#{size_reference_ids}}",
        active: true
      }
      DB[:fruit_actual_counts_for_packs].insert(default.merge(opts))
    end

    def create_fruit_size_reference(opts = {})
      default = {
        size_reference: Faker::Lorem.unique.word,
        edi_out_code: Faker::Lorem.word
      }
      DB[:fruit_size_references].insert(default.merge(opts))
    end
  end
end
