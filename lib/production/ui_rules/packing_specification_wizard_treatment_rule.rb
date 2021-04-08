# frozen_string_literal: true

module UiRules
  class PackingSpecificationWizardTreatmentRule < Base
    def generate_rules
      form_name 'packing_specification_wizard'

      common_values_for_fields common_fields
      make_header_table
    end

    def common_fields
      make_form_object
      {
        treatment_ids: { renderer: :multi,
                         options: MasterfilesApp::FruitRepo.new.for_select_treatments,
                         selected: @form_object.treatment_ids,
                         caption: 'Treatments' }

      }
    end

    def make_form_object
      @repo = ProductionApp::PackingSpecificationRepo.new
      apply_form_values
      form_object_merge!(@repo.extend_packing_specification(@form_object))
      @form_object
    end

    def make_header_table
      compact_header(UtilityFunctions.symbolize_keys(@form_object.compact_header))
    end

    private

    def form_object_merge!(params)
      params.to_h.each do |k, v|
        @form_object[k] = v
      end
    end
  end
end
