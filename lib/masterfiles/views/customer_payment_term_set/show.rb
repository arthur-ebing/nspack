# frozen_string_literal: true

module Masterfiles
  module Finance
    module CustomerPaymentTermSet
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:customer_payment_term_set, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Payment Term Set'
              form.view_only!
              form.add_field :customer
              form.add_field :incoterm
              form.add_field :deal_type
              form.add_field :payment_terms
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
