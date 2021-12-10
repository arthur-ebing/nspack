# frozen_string_literal: true

module Masterfiles
  module RawMaterials
    module RipenessCode
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:ripeness_code, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Ripeness Code'
              form.action "/masterfiles/raw_materials/ripeness_codes/#{id}"
              form.remote!
              form.method :update
              form.add_field :ripeness_code
              form.add_field :description
              form.add_field :legacy_code
            end
          end
        end
      end
    end
  end
end
