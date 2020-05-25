# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtDelivery
      class SetReceiveDate
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:set_receive_date, :set_receive_date, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Set Receive Date'
              form.action "/raw_materials/deliveries/rmt_deliveries/#{id}/set_receive_date"
              form.add_field :date_received
              form.add_field :date_delivered
            end
          end

          layout
        end
      end
    end
  end
end
