# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PalletBase
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pallet_base, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Pallet Base'
              form.view_only!
              form.add_field :pallet_base_code
              form.add_field :description
              form.add_field :length
              form.add_field :width
              form.add_field :edi_in_pallet_base
              form.add_field :edi_out_pallet_base
              form.add_field :cartons_per_layer
              form.add_field :material_mass
              form.add_field :active
              form.add_field :pallet_formats
            end
          end

          layout
        end
      end
    end
  end
end
