# frozen_string_literal: true

module Masterfiles
  module Fruit
    module InventoryCode
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:inventory_code, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Inventory Code'
              form.action "/masterfiles/fruit/inventory_codes/#{id}"
              form.remote!
              form.method :update
              form.add_field :inventory_code
              form.add_field :description
              form.add_field :edi_out_inventory_code
              form.add_field :fruit_item_incentive_rate
            end

            page.section do |section|
              section.show_border!
              section.add_control(control_type: :link,
                                  text: 'Create missing inventory packing costs',
                                  url: "/masterfiles/fruit/inventory_codes_packing_costs/#{id}/sync_inventory_packing_costs",
                                  behaviour: :replace_dialog,
                                  style: :button)

              section.add_grid('inventory_codes_packing_costs',
                               "/list/inventory_codes_packing_costs/grid?key=inventory_code&inventory_code_id=#{id}",
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
