# frozen_string_literal: true

module Masterfiles
  module RawMaterials
    module RmtDeliveryDestination
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:rmt_delivery_destination, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New RMT Delivery Destination'
              form.action '/masterfiles/raw_materials/rmt_delivery_destinations'
              form.remote! if remote
              form.add_field :delivery_destination_code
              form.add_field :description
            end
          end

          layout
        end
      end
    end
  end
end
