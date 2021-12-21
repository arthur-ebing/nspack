# frozen_string_literal: true

module UiRules
  class QcSampleTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::QcRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'qc_sample_type'
    end

    def set_show_fields
      fields[:qc_sample_type_name] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:default_sample_size] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:required_for_first_orchard_delivery] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        qc_sample_type_name: { renderer: :label, include_hidden_field: true },
        description: {},
        default_sample_size: { renderer: :integer },
        required_for_first_orchard_delivery: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_qc_sample_type(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::QcSampleType)
    end
  end
end
