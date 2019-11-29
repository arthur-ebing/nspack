# frozen_string_literal: true

module MasterfilesApp
  module PortFactory
    def create_port(opts = {})
      port_type_id = create_port_type
      voyage_type_id = create_voyage_type
      destination_city_id = create_destination_city

      default = {
        port_type_id: port_type_id,
        voyage_type_id: voyage_type_id,
        city_id: destination_city_id,
        port_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:ports].insert(default.merge(opts))
    end

    def create_port_type(opts = {})
      default = {
        port_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:port_types].insert(default.merge(opts))
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

    # def create_destination_city(opts = {})
    #   destination_country_id = create_destination_country
    #
    #   default = {
    #     destination_country_id: destination_country_id,
    #     city_name: Faker::Lorem.unique.word,
    #     active: true,
    #     updated_at: '2010-01-01 12:00',
    #     created_at: '2010-01-01 12:00'
    #   }
    #   DB[:destination_cities].insert(default.merge(opts))
    # end
    #
    # def create_destination_country(opts = {})
    #   destination_region_id = create_destination_region
    #
    #   default = {
    #     destination_region_id: destination_region_id,
    #     country_name: Faker::Lorem.unique.word,
    #     active: true,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00'
    #   }
    #   DB[:destination_countries].insert(default.merge(opts))
    # end
    #
    # def create_destination_region(opts = {})
    #   default = {
    #     destination_region_name: Faker::Lorem.unique.word,
    #     active: true,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00'
    #   }
    #   DB[:destination_regions].insert(default.merge(opts))
    # end
  end
end
