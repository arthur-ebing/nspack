# frozen_string_literal: true

module MasterfilesApp
  module VesselFactory
    def create_vessel(opts = {})
      vessel_type_id = create_vessel_type

      default = {
        vessel_type_id: vessel_type_id,
        vessel_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:vessels].insert(default.merge(opts))
    end

    def create_vessel_type(opts = {})
      voyage_type_id = create_voyage_type

      default = {
        voyage_type_id: voyage_type_id,
        vessel_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:vessel_types].insert(default.merge(opts))
    end

    def create_voyage_type(opts = {})
      default = {
        voyage_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:voyage_types].insert(default.merge(opts))
    end
  end
end
