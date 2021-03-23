# frozen_string_literal: true

module UiRules
  class BinTippingControlDataRule < Base
    attr_reader :repo

    def generate_rules
      @repo = MesscadaApp::MesscadaRepo.new
      make_form_object
      apply_form_values
      common_values_for_fields common_fields

      add_behaviours

      form_name 'bin_tipping_control_data'
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      run_cultivar = MasterfilesApp::CultivarRepo.new.find_production_run_cultivar(@options[:production_run_id])
      {
        rmt_product_type: { renderer: :select, options: %w[presort orchard_run rebin], required: true, prompt: true, min_charwidth: 30 },
        treatment_code: { renderer: :select, options: repo.run_treatment_codes, required: true, prompt: true },
        rmt_size: { renderer: :select, caption: 'Size Code', options: MasterfilesApp::RmtSizeRepo.new.for_select_rmt_sizes.map { |s| s[0] }.uniq, required: true, prompt: true },
        ripe_point_code: { renderer: :select, options: repo.ripe_point_codes.map { |s| s[0] }.uniq, required: true, prompt: true },
        pc_code: { renderer: :select, options: @form_object.pc_code ? [@form_object.pc_code] : [], required: true, prompt: true },
        product_class_code: { renderer: :select, options: MasterfilesApp::FruitRepo.new.for_select_rmt_classes.map { |s| s[0] }.uniq, required: true, prompt: true },
        track_indicator_code: { renderer: :select, options: repo.track_indicator_codes(run_cultivar).uniq, required: true, prompt: true },
        cold_store_type: { renderer: :select, options: %w[CA RA KT NO], required: true, prompt: true }
      }
    end

    def make_form_object
      @form_object = OpenStruct.new
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :ripe_point_code, notify: [{ url: '/production/runs/production_runs/ripe_point_code_combo_changed' }]
      end
    end
  end
end
