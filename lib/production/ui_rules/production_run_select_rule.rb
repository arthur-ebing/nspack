# frozen_string_literal: true

module UiRules
  class ProductionRunSelectRule < Base
    def generate_rules
      @repo = ProductionApp::ProductionRunRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      form_name 'production_run'
    end

    def common_fields
      {
        production_run_id: { renderer: :select,
                             options: @repo.for_select_labeling_run_lines,
                             caption: 'Production Line',
                             required: true }
      }
    end

    def make_form_object
      @form_object = OpenStruct.new(production_run_id: nil)
    end
  end
end
