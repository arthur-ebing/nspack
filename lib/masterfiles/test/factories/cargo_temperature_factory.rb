# frozen_string_literal: true

# ========================================================= #
# NB. Scaffolds for test factories should be combined       #
#     - Otherwise you'll have methods for the same table in #
#       several factories.                                  #
#     - Rather create a factory for several related tables  #
# ========================================================= #

module MasterfilesApp
  module CargoTemperatureFactory
    def create_cargo_temperature(opts = {})
      default = {
        temperature_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        set_point_temperature: Faker::Number.decimal,
        load_temperature: Faker::Number.decimal,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:cargo_temperatures].insert(default.merge(opts))
    end
  end
end
