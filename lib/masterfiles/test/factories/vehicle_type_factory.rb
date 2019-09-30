# frozen_string_literal: true

module MasterfilesApp
  module VehicleTypeFactory
    def create_vehicle_type(opts = {})
      default = {
        vehicle_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        has_container: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:vehicle_types].insert(default.merge(opts))
    end
  end
end
