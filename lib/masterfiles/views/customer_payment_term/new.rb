# frozen_string_literal: true

module Masterfiles
  module Finance
    module CustomerPaymentTerm
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:customer_payment_term, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Customer Payment Term'
              form.action '/masterfiles/finance/customer_payment_terms'
              form.remote! if remote
              form.add_field :payment_term_id
              form.add_field :customer_payment_term_set_id
            end
          end

          layout
        end
      end
    end
  end
end
