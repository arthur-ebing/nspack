# frozen_string_literal: true

module MasterfilesApp
  module QualityFactory
    def create_pallet_verification_failure_reason(opts = {})
      default = {
        reason: Faker::Lorem.unique.word,
        active: true
      }
      DB[:pallet_verification_failure_reasons].insert(default.merge(opts))
    end
  end
end
