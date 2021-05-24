# frozen_string_literal: true

module UiRules
  class CustomerPaymentTermRule < Base
    def generate_rules
      @repo = MasterfilesApp::FinanceRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'customer_payment_term'
    end

    def set_show_fields
      fields[:payment_term] = { renderer: :label }
      fields[:customer_payment_term_set] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        payment_term_id: { renderer: :select,
                           options: @repo.for_select_payment_terms,
                           disabled_options: @repo.for_select_inactive_payment_terms,
                           caption: 'Payment Term',
                           required: true },
        customer_payment_term_set_id: { renderer: :select,
                                        options: @repo.for_select_customer_payment_term_sets,
                                        disabled_options: @repo.for_select_inactive_customer_payment_term_sets,
                                        caption: 'Customer Payment Term Set',
                                        required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_customer_payment_term(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(payment_term_id: nil,
                                    customer_payment_term_set_id: nil)
    end
  end
end
