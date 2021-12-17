# frozen_string_literal: true

module QualityApp
  module QcFactory
    def create_qc_sample(opts = {})
      id = get_available_factory_record(:qc_samples, opts)
      return id unless id.nil?

      opts[:qc_sample_type_id] ||= create_qc_sample_type
      opts[:rmt_delivery_id] ||= create_rmt_delivery unless opts.key?(:rmt_delivery_id)
      opts[:production_run_id] ||= create_production_run unless opts.key?(:production_run_id)

      default = {
        coldroom_location_id: location_id,
        orchard_id: orchard_id,
        presort_run_lot_number: Faker::Lorem.unique.word,
        ref_number: Faker::Lorem.unique.word,
        short_description: Faker::Lorem.word,
        sample_size: Faker::Number.number(digits: 4),
        editing: false,
        completed: false,
        completed_at: '2010-01-01 12:00',
        drawn_at: '2010-01-01 12:00',
        rmt_bin_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:qc_samples].insert(default.merge(opts))
    end
  end
end
