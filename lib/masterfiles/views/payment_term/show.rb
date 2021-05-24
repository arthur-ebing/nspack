# frozen_string_literal: true

module Masterfiles
  module Finance
    module PaymentTerm
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:payment_term, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Payment Term'
              form.view_only!
              form.add_field :incoterm
              form.add_field :deal_type
              form.add_field :payment_term_date_type
              form.add_field :short_description
              form.add_field :long_description
              form.add_field :percentage
              form.add_field :days
              form.add_field :amount_per_carton
              form.add_field :for_liquidation
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
