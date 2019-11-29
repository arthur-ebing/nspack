# frozen_string_literal: true

module MasterfilesApp
  module InspectionFailureReasonFactory
    def create_inspection_failure_reason(opts = {})
      inspection_failure_type_id = create_inspection_failure_type

      default = {
        inspection_failure_type_id: inspection_failure_type_id,
        failure_reason: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        main_factor: false,
        secondary_factor: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:inspection_failure_reasons].insert(default.merge(opts))
    end
  end
end
