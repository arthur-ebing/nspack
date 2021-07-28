# frozen_string_literal: true

module FinishedGoodsApp
  module PalletHoldoverFactory
    def create_pallet_holdover(opts = {})
      id = get_available_factory_record(:pallet_holdovers, opts)
      return id unless id.nil?

      opts[:pallet_id] ||= create_pallet
      default = {
        holdover_quantity: Faker::Number.number(digits: 4),
        buildup_remarks: Faker::Lorem.unique.word,
        completed: false,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:pallet_holdovers].insert(default.merge(opts))
    end
  end
end
