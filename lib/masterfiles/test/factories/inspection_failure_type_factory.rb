# frozen_string_literal: true

module MasterfilesApp
  module InspectionFailureTypeFactory
    def create_inspection_failure_type(opts = {})
      default = {
        failure_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:inspection_failure_types].insert(default.merge(opts))
    end
  end
end
