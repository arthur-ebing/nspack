# frozen_string_literal: true

module Production
  module Shifts
    module ShiftException
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:shift_exception, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Shift Exception'
              form.view_only!
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
