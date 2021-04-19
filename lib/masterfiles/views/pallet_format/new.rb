# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PalletFormat
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pallet_format, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Pallet Format'
              form.action '/masterfiles/packaging/pallet_formats'
              form.remote! if remote
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
