# frozen_string_literal: true

module Masterfiles
  module Finance
    module Customer
      class New
        def self.call(rmt_customer, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:customer, :new, rmt_customer: rmt_customer, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Customer'
              form.action '/masterfiles/finance/customers'
              form.remote! if remote
              form.add_field :customer_party_role_id
              form.add_field :financial_account_code
              form.add_field :fruit_industry_levy_id
              form.add_field :default_currency_id
              form.add_field :bin_asset_trading_partner
              form.add_field :currency_ids
              form.add_field :contact_person_ids
              # Organization
              form.add_field :medium_description
              form.add_field :short_description
              form.add_field :long_description
              form.add_field :company_reg_no
              form.add_field :vat_number
              form.add_field :rmt_customer
            end
          end
        end
      end
    end
  end
end
