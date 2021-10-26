# frozen_string_literal: true

module UiRules
  class GradeRule < Base
    def generate_rules
      @repo = MasterfilesApp::FruitRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'grade'
    end

    def set_show_fields
      fields[:grade_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:rmt_grade] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:qa_level] = { renderer: :label }
      fields[:inspection_class] = { renderer: :label }
    end

    def common_fields
      {
        grade_code: { required: true },
        description: {},
        rmt_grade: { renderer: :checkbox,
                     caption: 'RMT Grade?' },
        qa_level: { renderer: :integer },
        inspection_class: { hint: '<p>RMT class to be shown on inspection documents.</p><p>Leave this blank if grades are acceptable for inspection.</p>' }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_grade(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::Grade)
    end
  end
end
