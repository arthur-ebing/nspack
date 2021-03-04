# frozen_string_literal: true

module UiRules
  class PaymentTermTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::FinanceRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'payment_term_type'
    end

    def set_show_fields
      fields[:payment_term_type] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        payment_term_type: { required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_payment_term_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(payment_term_type: nil)
    end
  end
end
