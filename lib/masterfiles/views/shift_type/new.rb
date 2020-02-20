# frozen_string_literal: true

module Masterfiles
  module HumanResources
    module ShiftType
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
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
              form.add_field :ph_plant_resource_id
              form.add_field :line_plant_resource_id
              form.add_field :employment_type_id
              form.add_field :start_hour
              form.add_field :end_hour
              form.add_field :day_night_or_custom
            end
          end

          layout
        end
      end
    end
  end
end
