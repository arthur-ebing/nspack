# frozen_string_literal: true

module UiRules
  class ContractTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::HumanResourcesRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'contract_type'
    end

    def set_show_fields
      fields[:code] = { renderer: :label }
      fields[:description] = { renderer: :label }
    end

    def common_fields
      {
        code: { required: true },
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_contract_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(code: nil,
                                    description: nil)
    end
  end
end
