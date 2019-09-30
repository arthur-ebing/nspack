# frozen_string_literal: true

module MasterfilesApp
  module PortFactory
    def create_port(opts = {})
      port_type_id = create_port_type
      voyage_type_id = create_voyage_type

      default = {
        port_type_id: port_type_id,
        voyage_type_id: voyage_type_id,
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
  end
end
