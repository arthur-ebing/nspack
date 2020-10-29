# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmBom
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:pm_bom, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Pm Bom'
              form.view_only!
              form.add_field :bom_code
              form.add_field :system_code
              form.add_field :erp_bom_code
              form.add_field :description
              form.add_field :active
              form.add_field :pm_boms_products
            end
          end

          layout
        end
      end
    end
  end
end
