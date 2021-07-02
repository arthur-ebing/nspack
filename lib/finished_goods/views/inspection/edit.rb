# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module Inspection
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:inspection, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Inspection'
              form.action "/finished_goods/inspection/inspections/#{id}"
              form.remote!
              form.method :update
              form.add_field :inspection_type_code
              form.add_field :pallet_number
              form.add_field :inspector_id
              form.add_field :passed
              form.add_field :inspection_failure_reason_ids
              form.add_field :remarks
            end
          end

          layout
        end
      end
    end
  end
end
