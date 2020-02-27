# frozen_string_literal: true

module Masterfiles
  module RawMaterials
    module AssetTransactionType
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:asset_transaction_type, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Asset Transaction Type'
              form.action "/masterfiles/raw_materials/asset_transaction_types/#{id}"
              form.remote!
              form.method :update
              form.add_field :transaction_type_code
              form.add_field :description
            end
          end

          layout
        end
      end
    end
  end
end
