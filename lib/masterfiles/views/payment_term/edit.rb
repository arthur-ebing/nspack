# frozen_string_literal: true

module Masterfiles
  module Finance
    module PaymentTerm
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:payment_term, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Payment Term'
              form.action "/masterfiles/finance/payment_terms/#{id}"
              form.remote!
              form.method :update
              form.add_field :payment_term_date_type_id
              form.add_field :short_description
              form.add_field :long_description
              form.add_field :percentage
              form.add_field :days
              form.add_field :amount_per_carton
              form.add_field :for_liquidation
            end
          end

          layout
        end
      end
    end
  end
end
