# frozen_string_literal: true

module FinishedGoods
  module Orders
    module Order
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:order, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Order'
              form.action '/finished_goods/orders/orders'
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :order_type_id
                  col.add_field :customer_party_role_id
                  col.add_field :contact_party_role_id
                  col.add_field :currency_id
                  col.add_field :deal_type_id
                  col.add_field :incoterm_id
                  col.add_field :customer_payment_term_set_id
                end
                row.column do |col|
                  col.add_field :target_customer_party_role_id
                  col.add_field :exporter_party_role_id
                  col.add_field :final_receiver_party_role_id
                  col.add_field :marketing_org_party_role_id
                  col.add_field :packed_tm_group_id
                  col.add_field :customer_order_number
                  col.add_field :internal_order_number
                  col.add_field :remarks
                  col.add_field :pricing_per_kg
                  col.add_field :load_id
                end
              end
            end
          end

          layout
        end
      end
    end
  end
end
