# frozen_string_literal: true

module FinishedGoods
  module Orders
    module Order
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:order, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Order'
              form.action "/finished_goods/orders/orders/#{id}"
              form.remote!
              form.method :update
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
