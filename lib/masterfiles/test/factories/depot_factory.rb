# frozen_string_literal: true

module MasterfilesApp
  module DepotFactory
    def create_depot(opts = {})
      id = get_available_factory_record(:depots, opts)
      return id unless id.nil?

      opts[:city_id] ||= create_destination_city
      default = {
        depot_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        bin_depot: true,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        magisterial_district: Faker::Lorem.word
      }
      DB[:depots].insert(default.merge(opts))
    end

    def create_destination_city(opts = {})
      id = get_available_factory_record(:destination_cities, opts)
      return id unless id.nil?

      opts[:destination_country_id] ||= create_destination_country
      default = {
        city_name: Faker::Lorem.unique.word,
        active: true,
        updated_at: '2010-01-01 12:00',
        created_at: '2010-01-01 12:00'
      }
      DB[:destination_cities].insert(default.merge(opts))
    end

    def create_destination_country(opts = {})
      id = get_available_factory_record(:destination_countries, opts)
      return id unless id.nil?

      opts[:destination_region_id] ||= create_destination_region
      default = {
        country_name: Faker::Lorem.unique.word,
        iso_country_code: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:destination_countries].insert(default.merge(opts))
    end

    def create_destination_region(opts = {})
      id = get_available_factory_record(:destination_regions, opts)
      return id unless id.nil?

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
