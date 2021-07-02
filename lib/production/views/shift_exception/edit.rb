# frozen_string_literal: true

module Production
  module Shifts
    module ShiftException
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:shift_exception, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Shift Exception'
              form.action "/production/shifts/shift_exceptions/#{id}"
              form.remote!
              form.method :update
              form.add_field :shift_id
              form.add_field :contract_worker_id
              form.add_field :contract_worker_name
              form.add_field :running_hours
              form.add_field :remarks
            end
          end

          layout
        end
      end
    end
  end
end
