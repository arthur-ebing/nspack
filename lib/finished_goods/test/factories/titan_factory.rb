# frozen_string_literal: true

module FinishedGoodsApp
  module TitanFactory
    def create_titan_request(opts = {})
      load_id = create_load
      govt_inspection_sheet_id = create_govt_inspection_sheet

      default = {
        load_id: load_id,
        govt_inspection_sheet_id: govt_inspection_sheet_id,
        request_doc: { test: Faker::Lorem.word },
        result_doc: { test: Faker::Lorem.word },
        request_type: Faker::Lorem.unique.word,
        transaction_id: Faker::Number.number(digits: 4),
        request_id: Faker::Number.number(digits: 4),
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:titan_requests].insert(BaseRepo.new.prepare_values_for_db(:titan_requests, default.merge(opts)))
    end
  end
end
