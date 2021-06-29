# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtDelivery
      class EditRefNumber
        def self.call(id, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:rmt_delivery, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.remote! if remote
              form.caption 'Set Reference Number'
              form.action "/raw_materials/deliveries/rmt_deliveries/#{id}/edit_ref_number"
              form.add_field :reference_number
            end
          end

          layout
        end
      end
    end
  end
end
