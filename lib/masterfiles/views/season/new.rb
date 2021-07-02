# frozen_string_literal: true

module Masterfiles
  module Calendar
    module Season
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:season, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Season'
              form.action '/masterfiles/calendar/seasons'
              form.remote! if remote
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
