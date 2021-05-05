# frozen_string_literal: true

module UiRules
  class OrderTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::FinanceRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'order_type'
    end

    def set_show_fields
      fields[:order_type] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        order_type: { force_uppercase: true,
                      required: true },
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_order_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(order_type: nil,
                                    description: nil)
    end
  end
end
