# frozen_string_literal: true

# ========================================================= #
# NB. Scaffolds for test factories should be combined       #
#     - Otherwise you'll have methods for the same table in #
#       several factories.                                  #
#     - Rather create a factory for several related tables  #
# ========================================================= #

module MasterfilesApp
  module RmtContainerMaterialTypeFactory
    def create_rmt_container_material_type(opts = {})
      rmt_container_type_id = create_rmt_container_type

      default = {
        rmt_container_type_id: rmt_container_type_id,
        container_material_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        tare_weight: Faker::Number.decimal
      }
      DB[:rmt_container_material_types].insert(default.merge(opts))
    end

    def create_rmt_container_type(opts = {})
      default = {
        container_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        tare_weight: Faker::Number.decimal
      }
      DB[:rmt_container_types].insert(default.merge(opts))
    end
  end
end
