# frozen_string_literal: true

module UiRules
  class BinTippingCriteriaRule < Base
    def generate_rules
      @repo = ProductionApp::ProductionRunRepo.new
      make_form_object
      apply_form_values
      common_values_for_fields common_fields

      add_behaviours

      form_name 'bin_tipping_criteria'
    end

    def common_fields
      {
        toggle: { renderer: :checkbox, caption: 'All' },
        farm_code: { renderer: :checkbox, required: true },
        commodity_code: { renderer: :checkbox, required: true },
        rmt_variety_code: { renderer: :checkbox, required: true },
        treatment_code: { renderer: :checkbox, required: true },
        rmt_size: { renderer: :checkbox, required: true },
        product_class_code: { renderer: :checkbox, required: true },
        rmt_product_type: { renderer: :checkbox, required: true },
        pc_code: { renderer: :checkbox, required: true },
        cold_store_type: { renderer: :checkbox, required: true },
        season_code: { renderer: :checkbox, required: true },
        track_indicator_code: { renderer: :checkbox, required: true },
        ripe_point_code: { renderer: :checkbox, required: true }
      }
    end

    def make_form_object
      run = @repo.find_production_run(@options[:production_run_id])
      @form_object = OpenStruct.new(run.legacy_bintip_criteria || { commodity_code: true, rmt_variety_code: true, treatment_code: true, rmt_size: true, product_class_code: true })
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.input_change :toggle, notify: [{ url: '/production/runs/toggle_bin_tipping_criteria' }]
      end
    end
  end
end
