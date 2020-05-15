# frozen_string_literal: true

module MasterfilesApp
  module DepotFactory
    def create_depot(opts = {})
      destination_city_id = create_destination_city

      default = {
        city_id: destination_city_id,
        depot_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        bin_depot: true,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:depots].insert(default.merge(opts))
    end

    def create_destination_city(opts = {})
      destination_country_id = create_destination_country

      default = {
        destination_country_id: destination_country_id,
        city_name: Faker::Lorem.unique.word,
        active: true,
        updated_at: '2010-01-01 12:00',
        created_at: '2010-01-01 12:00'
      }
      DB[:destination_cities].insert(default.merge(opts))
    end

    def create_destination_country(opts = {})
      destination_region_id = create_destination_region

      default = {
        destination_region_id: destination_region_id,
        country_name: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:destination_countries].insert(default.merge(opts))
    end

    def create_destination_region(opts = {})
      default = {
        destination_region_name: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:destination_regions].insert(default.merge(opts))
    end
  end
end
