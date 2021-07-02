# frozen_string_literal: true

module UiRules
  class PaymentTermDateTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::FinanceRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'payment_term_date_type'
    end

    def set_show_fields
      fields[:type_of_date] = { renderer: :label }
      fields[:no_days_after_etd] = { renderer: :label }
      fields[:no_days_after_eta] = { renderer: :label }
      fields[:no_days_after_atd] = { renderer: :label }
      fields[:no_days_after_ata] = { renderer: :label }
      fields[:no_days_after_invoice] = { renderer: :label }
      fields[:no_days_after_invoice_sent] = { renderer: :label }
      fields[:no_days_after_container_load] = { renderer: :label }
      fields[:anchor_to_date] = { renderer: :label }
      fields[:adjust_anchor_date_to_month_end] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        type_of_date: { required: true },
        no_days_after_etd: {},
        no_days_after_eta: {},
        no_days_after_atd: {},
        no_days_after_ata: {},
        no_days_after_invoice: {},
        no_days_after_invoice_sent: {},
        no_days_after_container_load: {},
        anchor_to_date: {},
        adjust_anchor_date_to_month_end: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_payment_term_date_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(type_of_date: nil,
                                    no_days_after_etd: nil,
                                    no_days_after_eta: nil,
                                    no_days_after_atd: nil,
                                    no_days_after_ata: nil,
                                    no_days_after_invoice: nil,
                                    no_days_after_invoice_sent: nil,
                                    no_days_after_container_load: nil,
                                    anchor_to_date: nil,
                                    adjust_anchor_date_to_month_end: nil)
    end
  end
end
