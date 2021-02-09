# frozen_string_literal: true

module FinishedGoodsApp
  module InspectionFactory
    def create_inspection(opts = {})
      inspection_type_id = create_inspection_type
      pallet_id = create_pallet
      inspector_id = create_inspector

      default = {
        inspection_type_id: inspection_type_id,
        pallet_id: pallet_id,
        inspector_id: inspector_id,
        inspection_failure_reason_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        passed: false,
        remarks: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:inspections].insert(default.merge(opts))
    end
  end
end
