# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module FinishedGoods
  module Orders
    module OrderItem
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:order_item, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Order Item'
              form.action '/finished_goods/orders/order_items'
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :order_id
                  col.add_field :load_id
                  col.add_field :commodity_id
                  col.add_field :basic_pack_id
                  col.add_field :standard_pack_id
                  col.add_field :actual_count_id
                  col.add_field :size_reference_id
                  col.add_field :grade_id
                  col.add_field :mark_id
                  col.add_field :marketing_variety_id
                end
                row.column do |col|
                  col.add_field :inventory_id
                  col.add_field :carton_quantity
                  col.add_field :price_per_carton
                  col.add_field :price_per_kg
                  col.add_field :sell_by_code
                  col.add_field :pallet_format_id
                  col.add_field :pm_mark_id
                  col.add_field :pm_bom_id
                  col.add_field :rmt_class_id
                  col.add_field :treatment_id
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
# rubocop:enable Metrics/BlockLength
