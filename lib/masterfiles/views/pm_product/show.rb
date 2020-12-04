# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmProduct
      class Show
        def self.call(id)  # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pm_product, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form do |form| # rubocop:disable Metrics/BlockLength
              # form.caption 'Pm Product'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :pm_type_id
                  col.add_field :composition_level
                  col.add_field :product_code
                  col.add_field :material_mass
                  col.add_field :basic_pack_id
                  col.add_field :items_per_unit
                  col.add_field :marketing_size_range_mm
                  col.add_field :minimum_size_mm
                  col.add_field :average_size_mm
                  col.add_field :maximum_weight_gm
                  col.add_field :active
                end

                row.column do |col|
                  col.add_field :pm_subtype_id
                  col.add_field :erp_code
                  col.add_field :description
                  col.add_field :height_mm
                  col.add_field :gross_weight_per_unit
                  col.add_field :marketing_weight_range
                  col.add_field :maximum_size_mm
                  col.add_field :minimum_weight_gm
                  col.add_field :average_weight_gm
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
