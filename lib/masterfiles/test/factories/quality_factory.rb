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

    def create_scrap_reason(opts = {})
      default = {
        scrap_reason: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        applies_to_pallets: false,
        applies_to_bins: false
      }
      DB[:scrap_reasons].insert(default.merge(opts))
    end
  end
end
