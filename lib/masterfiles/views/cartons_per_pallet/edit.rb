# frozen_string_literal: true

module Masterfiles
  module Packaging
    module CartonsPerPallet
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:cartons_per_pallet, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Cartons Per Pallet'
              form.action "/masterfiles/packaging/cartons_per_pallet/#{id}"
              form.remote!
              form.method :update
              form.add_field :description
              form.add_field :pallet_format_id
              form.add_field :basic_pack_id
              form.add_field :cartons_per_pallet
              form.add_field :layers_per_pallet
            end
          end

          layout
        end
      end
    end
  end
end
