# frozen_string_literal: true

module Masterfiles
  module Quality
    module Laboratory
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:laboratory, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Laboratory'
              form.action "/masterfiles/quality/laboratories/#{id}"
              form.remote!
              form.method :update
              form.add_field :lab_code
              form.add_field :lab_name
              form.add_field :description
            end
          end
        end
      end
    end
  end
end
