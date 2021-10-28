# frozen_string_literal: true

module Masterfiles
  module Finance
    module Customer
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:customer, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Customer'
              form.view_only!
              form.add_field :customer
              form.add_field :financial_account_code
              form.add_field :fruit_industry_levy
              form.add_field :default_currency
              form.add_field :currencies
              form.add_field :contact_people
              form.add_field :location_id
              form.add_field :bin_asset_trading_partner
              form.add_field :active
              # form.add_field :rmt_customer
            end
            unless ui_rule.form_object.rmt_customer
              page.section do |section|
                section.add_grid('customer_payment_term_sets',
                                 "/list/customer_payment_term_sets/grid?key=customer&id=#{id}",
                                 caption: 'Payment Term Sets')
              end
            end
          end
        end
      end
    end
  end
end
