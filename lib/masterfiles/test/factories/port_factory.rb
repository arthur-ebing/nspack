# frozen_string_literal: true

module MasterfilesApp
  module PortFactory
    def create_port(opts = {})
      destination_city_id = create_destination_city

      default = {
        port_type_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        voyage_type_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        city_id: destination_city_id,
        port_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:ports].insert(default.merge(opts))
    end
  end
end
