# frozen_string_literal: true

module FinishedGoods
  module Orders
    module OrderItem
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:order_item, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Order Item'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :order_id
                  col.add_field :load_id
                  col.add_field :commodity
                  col.add_field :basic_pack
                  col.add_field :standard_pack
                  col.add_field :actual_count
                  col.add_field :size_reference
                  col.add_field :grade
                  col.add_field :mark
                  col.add_field :marketing_variety
                end
                row.column do |col|
                  col.add_field :inventory
                  col.add_field :carton_quantity
                  col.add_field :price_per_carton
                  col.add_field :price_per_kg
                  col.add_field :sell_by_code
                  col.add_field :pallet_format
                  col.add_field :pkg_mark
                  col.add_field :pkg_bom
                  col.add_field :rmt_class
                  col.add_field :treatment
                  col.add_field :active
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
