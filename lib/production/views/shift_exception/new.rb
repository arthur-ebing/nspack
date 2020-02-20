# frozen_string_literal: true

module Production
  module Shifts
    module ShiftException
      class New
        def self.call(parent_id, contract_worker_id, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:shift_exception, :new, form_values: form_values, contract_worker_id: contract_worker_id, shift_id: parent_id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Shift Exception'
              form.action "/production/shifts/shifts/#{parent_id}/shift_exceptions"
              form.remote! if remote
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
