# frozen_string_literal: true

module QualityApp
  module MrlResultFactory
    def create_mrl_result(opts = {})
      id = get_available_factory_record(:mrl_results, opts)
      return id unless id.nil?

      opts[:cultivar_id] ||= create_cultivar unless opts.key?(:cultivar_id)
      opts[:puc_id] ||= create_puc unless opts.key?(:puc_id)
      opts[:season_id] ||= create_season
      opts[:rmt_delivery_id] ||= create_rmt_delivery unless opts.key?(:rmt_delivery_id)
      opts[:laboratory_id] ||= create_laboratory
      opts[:mrl_sample_type_id] ||= create_mrl_sample_type
      opts[:production_run_id] ||= create_production_run unless opts.key?(:production_run_id)
      opts[:farm_id] ||= create_farm
      opts[:orchard_id] ||= create_orchard

      default = {
        post_harvest_parent_mrl_result_id: nil,
        waybill_number: Faker::Lorem.unique.word,
        reference_number: Faker::Lorem.word,
        sample_number: Faker::Lorem.word,
        ph_level: Faker::Number.number(digits: 4),
        num_active_ingredients: Faker::Number.number(digits: 4),
        max_num_chemicals_passed: true,
        mrl_sample_passed: true,
        pre_harvest_result: true,
        post_harvest_result: false,
        active: true,
        fruit_received_at: '2010-01-01 12:00',
        sample_submitted_at: '2010-01-01 12:00',
        result_received_at: '2010-01-01 12:00',
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:mrl_results].insert(default.merge(opts))
    end
  end
end
