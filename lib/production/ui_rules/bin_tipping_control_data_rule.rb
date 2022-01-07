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

    def common_fields
      {
        rmt_class_id: { renderer: :select,
                        options: MasterfilesApp::FruitRepo.new.for_select_rmt_classes.uniq,
                        caption: 'Product Class',
                        prompt: true },
        colour_percentage_id: { renderer: :select,
                                options: repo.for_select_run_colour_percentages(@options[:production_run_id]),
                                caption: 'Colour',
                                prompt: true },
        actual_cold_treatment_id: { renderer: :select,
                                    options: @repo.for_select_treatments_by_type(AppConst::COLD_TREATMENT),
                                    prompt: true },
        actual_ripeness_treatment_id: { renderer: :select,
                                        options: @repo.for_select_treatments_by_type(AppConst::RIPENESS_TREATMENT),
                                        prompt: true },
        rmt_code_id: { renderer: :select,
                       options: @repo.for_select_rmt_codes_by_cultivar(@form_object.cultivar_id),
                       prompt: true },
        rmt_size_id: { renderer: :select,
                       options: MasterfilesApp::RmtSizeRepo.new.for_select_rmt_sizes,
                       prompt: true }
      }
    end

    def make_form_object
      @form_object = OpenStruct.new

      production_run = @repo.find_hash(:production_runs, @options[:production_run_id])
      return if production_run.nil?

      fields = %i[colour_percentage_id actual_cold_treatment_id actual_ripeness_treatment_id cultivar_id rmt_code_id rmt_size_id rmt_class_id]
      hash = Hash[fields.zip(fields.map { |f| production_run[f] })]
      @form_object = OpenStruct.new(hash)
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :ripe_point_code, notify: [{ url: '/production/runs/production_runs/ripe_point_code_combo_changed' }]
      end
    end
  end
end
