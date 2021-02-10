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
      fields[:treatment_code] = { renderer: :checkbox, disabled: true }
      fields[:rmt_size] = { renderer: :checkbox, disabled: true }
      fields[:product_class_code] = { renderer: :checkbox, disabled: true }
      fields[:rmt_product_type] = { renderer: :checkbox, disabled: true }
      fields[:pc_code] = { renderer: :checkbox, disabled: true }
      fields[:cold_store_type] = { renderer: :checkbox, disabled: true }
      fields[:season_code] = { renderer: :checkbox, disabled: true }
      fields[:track_indicator_code] = { renderer: :checkbox, disabled: true }
      fields[:ripe_point_code] = { renderer: :checkbox, disabled: true }
      fields[:rmt_product_type_label] = { renderer: :label, caption: 'Rmt Product Type', min_charwidth: 30 }
      fields[:treatment_code_label] = { renderer: :label, caption: 'Treatment Code' }
      fields[:rmt_size_label] = { renderer: :label, caption: 'Rmt Size' }
      fields[:ripe_point_code_label] = { renderer: :label, caption: 'Ripe Point Code' }
      fields[:pc_code_label] = { renderer: :label, caption: 'Pc Code', min_charwidth: 30 }
      fields[:product_class_code_label] = { renderer: :label, caption: 'Product Class Code' }
      fields[:track_indicator_code_label] = { renderer: :label, caption: 'Track Indicator Code' }
      fields[:cold_store_type_label] = { renderer: :label, caption: 'Cold Store Type' }
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

    def make_form_object # rubocop:disable Metrics/AbcSize
      run = @repo.find_production_run(@options[:production_run_id])
      attrs = run.legacy_bintip_criteria || { commodity_code: true, rmt_variety_code: true, treatment_code: true, rmt_size: true, product_class_code: true }
      if @mode == :show
        legacy_bintip_criteria = run.legacy_bintip_criteria || {}
        legacy_data = run.legacy_data || {}
        attrs = { farm_code: legacy_bintip_criteria['farm_code'], commodity_code: legacy_bintip_criteria['commodity_code'], rmt_variety_code: legacy_bintip_criteria['rmt_variety_code'],
                  treatment_code: legacy_bintip_criteria['treatment_code'], rmt_size: legacy_bintip_criteria['rmt_size'], product_class_code: legacy_bintip_criteria['product_class_code'],
                  rmt_product_type: legacy_bintip_criteria['rmt_product_type'], pc_code: legacy_bintip_criteria['pc_code'], cold_store_type: legacy_bintip_criteria['cold_store_type'],
                  season_code: legacy_bintip_criteria['season_code'], track_indicator_code: legacy_bintip_criteria['track_indicator_code'], ripe_point_code: legacy_bintip_criteria['ripe_point_code'],
                  rmt_product_type_label: legacy_data['rmt_product_type'], treatment_code_label: legacy_data['treatment_code'], rmt_size_label: legacy_data['rmt_size'],
                  ripe_point_code_label: legacy_data['ripe_point_code'], pc_code_label: legacy_data['pc_code'], product_class_code_label: legacy_data['product_class_code'],
                  track_indicator_code_label: legacy_data['track_indicator_code'], cold_store_type_label: legacy_data['cold_store_type'] }
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
