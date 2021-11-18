# frozen_string_literal: true

module Masterfiles
  module HumanResources
    module ShiftType
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:shift_type, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Shift Type'
              form.action '/masterfiles/human_resources/shift_types'
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :ph_plant_resource_id
                  col.add_field :line_plant_resource_id
                  col.add_field :employment_type_id
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :start_hour
                  col.add_field :end_hour
                end
                row.column do |col|
                  col.add_field :starting_quarter
                  col.add_field :ending_quarter
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :day_night_or_custom
                end
              end
            end
          end

          layout
        end
      end
    end
  end
end
