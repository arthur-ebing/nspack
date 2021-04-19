# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PalletFormat
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pallet_format, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Pallet Format'
              form.action "/masterfiles/packaging/pallet_formats/#{id}"
              form.remote!
              form.method :update
              form.add_field :description
              form.add_field :pallet_base_id
              form.add_field :pallet_stack_type_id
              form.add_field :bin
            end
          end

          layout
        end
      end
    end
  end
end
