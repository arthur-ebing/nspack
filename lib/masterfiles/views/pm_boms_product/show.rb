# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmBomsProduct
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:pm_boms_product, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Pm Boms Product'
              form.view_only!
              form.add_field :pm_subtype_id
              form.add_field :pm_product_id
              form.add_field :pm_bom_id
              form.add_field :uom_id
              form.add_field :quantity
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
