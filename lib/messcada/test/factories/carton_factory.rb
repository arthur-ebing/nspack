# frozen_string_literal: true

module MesscadaApp
  module CartonFactory
    def create_carton(opts = {})
      # id = get_available_factory_record(:cartons, opts)
      # return id unless id.nil?

      default = {
        carton_label_id: create_carton_label,
        gross_weight: Faker::Number.decimal,
        nett_weight: Faker::Number.decimal,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        palletizer_identifier_id: create_personnel_identifier,
        pallet_sequence_id: create_pallet_sequence,
        palletizing_bay_resource_id: create_plant_resource,
        is_virtual: false,
        scrapped: false,
        scrapped_reason: Faker::Lorem.unique.word,
        scrapped_at: '2010-01-01 12:00',
        scrapped_sequence_id: Faker::Number.number(digits: 4),
        palletizer_contract_worker_id: create_contract_worker
      }
      DB[:cartons].insert(default.merge(opts))
    end
  end
end
