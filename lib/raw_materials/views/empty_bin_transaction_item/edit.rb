# frozen_string_literal: true

module RawMaterials
  module EmptyBins
    module EmptyBinTransactionItem
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:empty_bin_transaction_item, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Empty Bin Transaction Item'
              form.action "/raw_materials/empty_bins/empty_bin_transaction_items/#{id}"
              form.remote!
              form.method :update
              # form.add_field :empty_bin_transaction_id
              # form.add_field :rmt_container_material_owner_id
              # form.add_field :empty_bin_from_location_id
              # form.add_field :empty_bin_to_location_id
              # form.add_field :quantity_bins
            end
          end

          layout
        end
      end
    end
  end
end
