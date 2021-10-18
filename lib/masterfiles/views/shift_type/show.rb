# frozen_string_literal: true

module Masterfiles
  module HumanResources
    module ShiftType
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:shift_type, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Shift Type'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :shift_type_code
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
