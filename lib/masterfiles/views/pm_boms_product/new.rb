# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmBomsProduct
      class New
        def self.call(pm_bom_id, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pm_boms_product, :new, pm_bom_id: pm_bom_id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New PKG BOMs Product'
              form.action "/masterfiles/packaging/pm_boms/#{pm_bom_id}/pm_boms_products"
              form.remote! if remote
              form.add_field :pm_subtype_id
              form.add_field :pm_product_id
              form.add_field :pm_bom_id
              form.add_field :pm_bom
              form.add_field :uom_id
              form.add_field :quantity
            end
          end

          layout
        end
      end
    end
  end
end
