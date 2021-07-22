# frozen_string_literal: true

module Masterfiles
  module Fruit
    module InventoryCode
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:inventory_code, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Inventory Code'
              form.view_only!
              form.add_field :inventory_code
              form.add_field :description
              form.add_field :edi_out_inventory_code
              form.add_field :fruit_item_incentive_rate
              form.add_field :active
            end

            page.section do |section|
              section.add_grid('inventory_codes_packing_costs',
                               "/list/inventory_codes_packing_costs_show/grid?key=inventory_code&inventory_code_id=#{id}",
                               height: 16,
                               caption: 'Inventory Packing Costs')
            end
          end

          layout
        end
      end
    end
  end
end
