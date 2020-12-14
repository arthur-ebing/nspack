# frozen_string_literal: true

module FinishedGoodsApp
  module VoyageFactory
    def create_voyage(opts = {})
      vessel_id = create_vessel
      voyage_type_id = create_voyage_type

      default = {
        vessel_id: vessel_id,
        voyage_type_id: voyage_type_id,
        voyage_number: Faker::Lorem.unique.word,
        voyage_code: Faker::Lorem.unique.word,
        year: Faker::Number.number(digits: 4),
        completed: false,
        completed_at: '2010-01-01 12:00',
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:voyages].insert(default.merge(opts))
    end
  end
end
