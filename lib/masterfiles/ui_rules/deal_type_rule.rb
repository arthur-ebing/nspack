# frozen_string_literal: true

module UiRules
  class DealTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::FinanceRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'deal_type'
    end

    def set_show_fields
      fields[:deal_type] = { renderer: :label }
      fields[:fixed_amount] = { renderer: :label,
                                as_boolean: true }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
    end

    def common_fields
      {
        deal_type: {},
        fixed_amount: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_deal_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(deal_type: nil,
                                    fixed_amount: nil)
    end
  end
end
