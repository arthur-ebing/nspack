# frozen_string_literal: true

module UiRules
  class InspectionFailureTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::QualityRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'inspection_failure_type'
    end

    def set_show_fields
      fields[:failure_type_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        failure_type_code: { required: true },
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_inspection_failure_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(failure_type_code: nil,
                                    description: nil)
    end
  end
end
