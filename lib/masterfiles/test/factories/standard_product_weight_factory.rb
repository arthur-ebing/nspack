# frozen_string_literal: true

module MasterfilesApp
  module StandardProductWeightFactory
    def create_standard_product_weight(opts = {})
      commodity_id = create_commodity
      standard_pack_code_id = create_standard_pack

      default = {
        commodity_id: commodity_id,
        standard_pack_id: standard_pack_code_id,
        gross_weight: Faker::Number.decimal,
        nett_weight: Faker::Number.decimal,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        standard_carton_nett_weight: Faker::Number.decimal,
        ratio_to_standard_carton: Faker::Number.decimal,
        is_standard_carton: false
      }
      DB[:standard_product_weights].insert(default.merge(opts))
    end

    def create_standard_pack(opts = {})
      default = {
        standard_pack_code: Faker::Lorem.unique.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        active: true,
        material_mass: Faker::Number.decimal,
        plant_resource_button_indicator: Faker::Lorem.word,
        description: Faker::Lorem.word,
        std_pack_label_code: Faker::Lorem.word
      }
      DB[:standard_pack_codes].insert(default.merge(opts))
    end
  end
end
