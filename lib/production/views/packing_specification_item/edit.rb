# frozen_string_literal: true

module Production
  module PackingSpecifications
    module PackingSpecificationItem
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:packing_specification_item, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Packing Specification Item'
              form.action "/production/packing_specifications/packing_specification_items/#{id}"
              form.remote!
              form.method :update
              form.add_field :product_setup
              form.add_field :description
              form.add_field :product_setup_id
              form.add_field :pm_bom_id
              form.add_field :pm_mark_id
              form.add_field :tu_labour_product_id
              form.add_field :ru_labour_product_id
              form.add_field :ri_labour_product_id
              form.add_field :fruit_sticker_ids
              form.add_field :tu_sticker_ids
              form.add_field :ru_sticker_ids
            end
          end

          layout
        end
      end
    end
  end
end
