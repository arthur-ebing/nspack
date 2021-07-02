# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmProduct
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:pm_product, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit PKG Product'
              form.action "/masterfiles/packaging/pm_products/#{id}"
              form.remote!
              form.method :update
              form.add_field :pm_subtype_id
              form.add_field :pm_subtype
              form.add_field :composition_level
              form.add_field :erp_code
              form.add_field :product_code
              form.add_field :description
              form.add_field :material_mass
              form.add_field :basic_pack_id
              form.add_field :height_mm
              form.add_field :gross_weight_per_unit
              form.add_field :items_per_unit
              form.add_field :items_per_unit_client_description
            end
          end

          layout
        end
      end
    end
  end
end
