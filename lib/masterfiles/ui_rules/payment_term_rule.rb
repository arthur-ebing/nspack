# frozen_string_literal: true

module UiRules
  class PaymentTermRule < Base
    def generate_rules
      @repo = MasterfilesApp::FinanceRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'payment_term'
    end

    def set_show_fields
      fields[:incoterm] = { renderer: :label }
      fields[:deal_type] = { renderer: :label }
      fields[:payment_term_date_type] = { renderer: :label }
      fields[:short_description] = { renderer: :label }
      fields[:long_description] = { renderer: :label }
      fields[:percentage] = { renderer: :label }
      fields[:days] = { renderer: :label }
      fields[:amount_per_carton] = { renderer: :label }
      fields[:for_liquidation] = { renderer: :label,
                                   as_boolean: true }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
    end

    def common_fields
      {
        incoterm_id: { renderer: :select,
                       options: @repo.for_select_incoterms,
                       disabled_options: @repo.for_select_inactive_incoterms,
                       caption: 'Incoterm',
                       required: true },
        deal_type_id: { renderer: :select,
                        options: @repo.for_select_deal_types,
                        disabled_options: @repo.for_select_inactive_deal_types,
                        caption: 'Deal Type',
                        required: true },
        payment_term_date_type_id: { renderer: :select,
                                     options: @repo.for_select_payment_term_date_types,
                                     disabled_options: @repo.for_select_inactive_payment_term_date_types,
                                     caption: 'Payment Term Date Type',
                                     required: true },
        short_description: { required: true },
        long_description: {},
        percentage: {},
        days: {},
        amount_per_carton: {},
        for_liquidation: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_payment_term(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(incoterm_id: nil,
                                    deal_type_id: nil,
                                    payment_term_date_type_id: nil,
                                    short_description: nil,
                                    long_description: nil,
                                    percentage: nil,
                                    days: nil,
                                    amount_per_carton: nil,
                                    for_liquidation: nil)
    end
  end
end
