# frozen_string_literal: true

module Production
  module PackingSpecifications
    module PackingSpecificationItem
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:packing_specification_item, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Packing Specification Item'
              form.view_only!
              form.add_field :packing_specification
              form.add_field :product_setup
              form.add_field :description
              form.add_field :pm_bom
              form.add_field :pm_mark
              form.add_field :tu_labour_product
              form.add_field :ru_labour_product
              form.add_field :ri_labour_product
              form.add_field :fruit_stickers
              form.add_field :tu_stickers
              form.add_field :ru_stickers
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
