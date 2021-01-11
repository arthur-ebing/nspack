# frozen_string_literal: true

module FinishedGoodsApp
  module LoadVehicleFactory
    def create_load_vehicle(opts = {})
      load_id = create_load
      vehicle_type_id = create_vehicle_type
      haulier_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_HAULIER)

      default = {
        load_id: load_id,
        vehicle_type_id: vehicle_type_id,
        haulier_party_role_id: haulier_party_role_id,
        vehicle_number: Faker::Lorem.unique.word,
        vehicle_weight_out: Faker::Number.decimal,
        dispatch_consignment_note_number: Faker::Lorem.word,
        driver_name: Faker::Lorem.word,
        driver_cell_number: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:load_vehicles].insert(default.merge(opts))
    end

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
