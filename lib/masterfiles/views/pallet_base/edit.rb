# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PalletBase
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pallet_base, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Pallet Base'
              form.action "/masterfiles/packaging/pallet_bases/#{id}"
              form.remote!
              form.method :update
              form.add_field :pallet_base_code
              form.add_field :description
              form.add_field :length
              form.add_field :width
              form.add_field :edi_in_pallet_base
              form.add_field :edi_out_pallet_base
              form.add_field :cartons_per_layer
              form.add_field :material_mass
            end
          end

          layout
        end
      end
    end
  end
end
