# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PalletStackType
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:pallet_stack_type, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Pallet Stack Type'
              form.action "/masterfiles/packaging/pallet_stack_types/#{id}"
              form.remote!
              form.method :update
              form.add_field :stack_type_code
              form.add_field :description
              form.add_field :stack_height
            end
          end

          layout
        end
      end
    end
  end
end
