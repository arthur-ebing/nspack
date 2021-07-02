# frozen_string_literal: true

module Masterfiles
  module Calendar
    module SeasonGroup
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:season_group, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Season Group'
              form.action "/masterfiles/calendar/season_groups/#{id}"
              form.remote!
              form.method :update
              form.add_field :season_group_code
              form.add_field :description
              form.add_field :season_group_year
            end
          end

          layout
        end
      end
    end
  end
end
