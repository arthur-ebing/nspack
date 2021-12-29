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
        applies_to_bins: false,
        applies_to_cartons: false
      }
      DB[:scrap_reasons].insert(default.merge(opts))
    end

    def create_laboratory(opts = {})
      id = get_available_factory_record(:laboratories, opts)
      return id unless id.nil?

      default = {
        lab_code: Faker::Lorem.unique.word,
        lab_name: Faker::Lorem.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:laboratories].insert(default.merge(opts))
    end

    def create_mrl_sample_type(opts = {})
      id = get_available_factory_record(:mrl_sample_types, opts)
      return id unless id.nil?

      default = {
        sample_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:mrl_sample_types].insert(default.merge(opts))
    end
  end
end
