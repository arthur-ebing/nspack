# frozen_string_literal: true

module UiRules
  class IncotermRule < Base
    def generate_rules
      @repo = MasterfilesApp::FinanceRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'incoterm'
    end

    def set_show_fields
      fields[:incoterm] = { renderer: :label }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
    end

    def common_fields
      {
        incoterm: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_incoterm(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(incoterm: nil)
    end
  end
end
