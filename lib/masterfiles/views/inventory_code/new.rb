# frozen_string_literal: true

module Masterfiles
  module Fruit
    module InventoryCode
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:inventory_code, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Inventory Code'
              form.action '/masterfiles/fruit/inventory_codes'
              form.remote! if remote
              form.add_field :inventory_code
              form.add_field :description
              form.add_field :edi_out_inventory_code
              form.add_field :fruit_item_incentive_rate
            end
          end

          layout
        end
      end
    end
  end
end
