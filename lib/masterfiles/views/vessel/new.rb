# frozen_string_literal: true

module Masterfiles
  module Shipping
    module Vessel
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:vessel, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Vessel'
              form.action '/masterfiles/shipping/vessels'
              form.remote! if remote
              form.add_field :vessel_type_id
              form.add_field :vessel_code
              form.add_field :description
            end
          end

          layout
        end
      end
    end
  end
end
