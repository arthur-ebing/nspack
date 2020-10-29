# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmProduct
      class Show
        def self.call(id)  # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pm_product, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Pm Product'
              form.view_only!
              form.add_field :pm_type_id
              form.add_field :pm_subtype_id
              form.add_field :erp_code
              form.add_field :product_code
              form.add_field :description
              form.add_field :material_mass
              form.add_field :height_mm
              form.add_field :basic_pack_id
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
