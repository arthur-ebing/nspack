# frozen_string_literal: true

module UiRules
  class LaboratoryRule < Base
    def generate_rules
      @repo = MasterfilesApp::QualityRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'laboratory'
    end

    def set_show_fields
      fields[:lab_code] = { renderer: :label }
      fields[:lab_name] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        lab_code: { required: true },
        lab_name: {},
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_laboratory(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::Laboratory)
    end
  end
end
