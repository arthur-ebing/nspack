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
      # payment_term_id_label = MasterfilesApp::PaymentTermRepo.new.find_payment_term(@form_object.payment_term_id)&.short_description
      # payment_term_id_label = @repo.find(:payment_terms, MasterfilesApp::PaymentTerm, @form_object.payment_term_id)&.short_description
      payment_term_id_label = @repo.get(:payment_terms, @form_object.payment_term_id, :short_description)
      # customer_payment_term_set_id_label = MasterfilesApp::CustomerPaymentTermSetRepo.new.find_customer_payment_term_set(@form_object.customer_payment_term_set_id)&.id
      # customer_payment_term_set_id_label = @repo.find(:customer_payment_term_sets, MasterfilesApp::CustomerPaymentTermSet, @form_object.customer_payment_term_set_id)&.id
      customer_payment_term_set_id_label = @repo.get(:customer_payment_term_sets, @form_object.customer_payment_term_set_id, :id)
      fields[:payment_term_id] = { renderer: :label, with_value: payment_term_id_label, caption: 'Payment Term' }
      fields[:customer_payment_term_set_id] = { renderer: :label, with_value: customer_payment_term_set_id_label, caption: 'Customer Payment Term Set' }
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
