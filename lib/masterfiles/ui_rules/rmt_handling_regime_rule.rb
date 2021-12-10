# frozen_string_literal: true

module UiRules
  class RmtHandlingRegimeRule < Base
    def generate_rules
      @repo = MasterfilesApp::AdvancedClassificationsRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'rmt_handling_regime'
    end

    def set_show_fields
      fields[:regime_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:for_packing] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        regime_code: { required: true },
        description: {},
        for_packing: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_rmt_handling_regime(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::RmtHandlingRegime)
    end
  end
end
