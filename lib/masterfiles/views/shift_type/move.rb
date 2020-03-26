# frozen_string_literal: true

module Masterfiles
  module HumanResources
    module ShiftType
      class Move
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:shift_type, :move, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Move Shift Type Employees'
              form.action '/masterfiles/human_resources/shift_types/move_employees'
              form.remote! if remote
              form.add_field :from_shift_type_id
              form.add_field :to_shift_type_id
            end
          end

          layout
        end
      end
    end
  end
end
