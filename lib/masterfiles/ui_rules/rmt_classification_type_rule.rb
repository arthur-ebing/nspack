# frozen_string_literal: true

module UiRules
  class RmtClassificationTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::AdvancedClassificationsRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'rmt_classification_type'
    end

    def set_show_fields
      fields[:rmt_classification_type_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:required_for_delivery] = { renderer: :label, as_boolean: true }
      fields[:physical_attribute] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        rmt_classification_type_code: { required: true },
        required_for_delivery: { renderer: :checkbox },
        physical_attribute: { renderer: :checkbox },
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_rmt_classification_type(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::RmtClassificationType)
    end
  end
end
