# frozen_string_literal: true

module MasterfilesApp
  module PortTypeFactory
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
  end
end
