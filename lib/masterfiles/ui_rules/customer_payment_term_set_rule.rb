# frozen_string_literal: true

module UiRules
  class CustomerPaymentTermSetRule < Base
    def generate_rules
      @repo = MasterfilesApp::FinanceRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields

      form_name 'customer_payment_term_set'
    end

    def set_show_fields
      fields[:incoterm] = { renderer: :label }
      fields[:deal_type] = { renderer: :label }
      fields[:customer] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        customer_id: { renderer: :select,
                       options: @repo.for_select_customers,
                       disabled_options: @repo.for_select_customers(active: false),
                       caption: 'Customer',
                       hide_on_load: @mode == :edit },
        incoterm_id: { renderer: :select,
                       options: @repo.for_select_incoterms,
                       disabled_options: @repo.for_select_inactive_incoterms,
                       caption: 'Incoterm' },
        deal_type_id: { renderer: :select,
                        options: @repo.for_select_deal_types,
                        disabled_options: @repo.for_select_inactive_deal_types,
                        caption: 'Deal Type' }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_customer_payment_term_set(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(incoterm_id: nil,
                                    deal_type_id: nil,
                                    customer_id: nil)
    end
  end
end
