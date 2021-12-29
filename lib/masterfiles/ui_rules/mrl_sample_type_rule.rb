# frozen_string_literal: true

module UiRules
  class MrlSampleTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::QualityRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'mrl_sample_type'
    end

    def set_show_fields
      fields[:sample_type_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        sample_type_code: { required: true },
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_mrl_sample_type(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::MrlSampleType)
    end
  end
end
