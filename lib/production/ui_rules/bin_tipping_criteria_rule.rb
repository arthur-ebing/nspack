# frozen_string_literal: true

module UiRules
  class BinTippingCriteriaRule < Base
    def generate_rules
      @repo = ProductionApp::ProductionRunRepo.new
      make_form_object
      apply_form_values
      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      add_behaviours

      form_name 'bin_tipping_criteria'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:farm_code] = { renderer: :checkbox, disabled: true }
      fields[:commodity_code] = { renderer: :checkbox, disabled: true }
      fields[:rmt_variety_code] = { renderer: :checkbox, disabled: true }
      fields[:season_code] = { renderer: :checkbox, disabled: true }
      fields[:rmt_size] = { renderer: :checkbox, disabled: true }
      fields[:rmt_code] = { renderer: :checkbox, disabled: true }
      fields[:colour_percentage] = { renderer: :checkbox, disabled: true }
      fields[:actual_ripeness_treatment] = { renderer: :checkbox, disabled: true }
      fields[:actual_cold_treatment] = { renderer: :checkbox, disabled: true }
      fields[:product_class_code] = { renderer: :checkbox, disabled: true }
      fields[:product_class_label] = { renderer: :label, caption: 'Product Class', disabled: true  }
      fields[:colour_percentage_label] = { renderer: :label, caption: 'Colour', disabled: true }
      fields[:actual_cold_treatment_label] = { renderer: :label, caption: 'Actual Cold Treatment', disabled: true }
      fields[:actual_ripeness_treatment_label] = { renderer: :label, caption: 'Actual Ripeness Treatment', disabled: true }
      fields[:rmt_code_label] = { renderer: :label, caption: 'Rmt Code', disabled: true }
      fields[:rmt_size_label] = { renderer: :label, caption: 'Rmt Size Code', disabled: true }
    end

    def common_fields
      {
        toggle: { renderer: :checkbox, caption: 'All' },
        farm_code: { renderer: :checkbox, required: true },
        commodity_code: { renderer: :checkbox, required: true },
        rmt_variety_code: { renderer: :checkbox, required: true },
        product_class_code: { renderer: :checkbox, required: true },
        season_code: { renderer: :checkbox, required: true },
        colour_percentage: { renderer: :checkbox, required: true, caption: 'Colour' },
        actual_cold_treatment: { renderer: :checkbox, required: true },
        actual_ripeness_treatment: { renderer: :checkbox, required: true },
        rmt_code: { renderer: :checkbox, required: true },
        rmt_size: { renderer: :checkbox, required: true }
      }
    end

    def make_form_object # rubocop:disable Metrics/AbcSize
      run = @repo.find_production_run(@options[:production_run_id])
      attrs = run.legacy_bintip_criteria
      if @mode == :show
        legacy_bintip_criteria = run.legacy_bintip_criteria || {}
        attrs = { farm_code: legacy_bintip_criteria['farm_code'], commodity_code: legacy_bintip_criteria['commodity_code'], rmt_variety_code: legacy_bintip_criteria['rmt_variety_code'],
                  rmt_size: legacy_bintip_criteria['rmt_size'], product_class_code: legacy_bintip_criteria['product_class_code'],
                  season_code: legacy_bintip_criteria['season_code'], actual_cold_treatment: legacy_bintip_criteria['actual_cold_treatment'], actual_ripeness_treatment: legacy_bintip_criteria['actual_ripeness_treatment'],
                  rmt_code: legacy_bintip_criteria['rmt_code'], colour_percentage_label: @repo.get_value(:colour_percentages, :colour_percentage, id: run.colour_percentage_id),
                  product_class_label: @repo.get_value(:rmt_classes, :rmt_class_code, id: run.rmt_class_id),
                  actual_cold_treatment_label: @repo.get_value(:treatments, :treatment_code, id: run.actual_cold_treatment_id),
                  actual_ripeness_treatment_label: @repo.get_value(:treatments, :treatment_code, id: run.actual_ripeness_treatment_id),
                  colour_percentage: legacy_bintip_criteria['colour_percentage'], rmt_code_label: @repo.get_value(:rmt_codes, :rmt_code, id: run.rmt_code_id),
                  rmt_size_label: @repo.get_value(:rmt_sizes, :size_code, id: run.rmt_size_id) }
      end

      @form_object = OpenStruct.new(attrs)
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.input_change :toggle, notify: [{ url: '/production/runs/toggle_bin_tipping_criteria' }]
      end
    end
  end
end
