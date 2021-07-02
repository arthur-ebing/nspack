# frozen_string_literal: true

module Masterfiles
  module Calendar
    module Season
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:season, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Season'
              form.action "/masterfiles/calendar/seasons/#{id}"
              form.remote!
              form.method :update
              form.add_field :season_group_id
              form.add_field :commodity_id
              form.add_field :season_code
              form.add_field :description
              form.add_field :season_year
              form.add_field :start_date
              form.add_field :end_date
            end
          end

          layout
        end
      end
    end
  end
end
