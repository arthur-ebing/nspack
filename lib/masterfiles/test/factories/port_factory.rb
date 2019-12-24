# frozen_string_literal: true

module MasterfilesApp
  module PortFactory
    def create_port(opts = {})
      destination_city_id = create_destination_city
      port_type_id = create_port_type
      voyage_type_id = create_voyage_type

      default = {
        city_id: destination_city_id,
        port_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        port_type_ids: BaseRepo.new.array_for_db_col([port_type_id]),
        voyage_type_ids: BaseRepo.new.array_for_db_col([voyage_type_id])
      }
      DB[:ports].insert(default.merge(opts))
    end
  end
end
