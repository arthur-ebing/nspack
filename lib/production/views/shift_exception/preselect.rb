# frozen_string_literal: true

module Production
  module Shifts
    module ShiftException
      class Preselect
        def self.call(parent_id, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:shift_exception, :preselect, form_values: form_values, shift_id: parent_id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Select Contract Worker'
              form.action "/production/shifts/shifts/#{parent_id}/shift_exceptions/new"
              form.remote! if remote
              form.add_field :shift_id
              form.add_field :contract_worker_id
            end
          end

          layout
        end
      end
    end
  end
end
