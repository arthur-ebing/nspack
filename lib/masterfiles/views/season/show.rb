# frozen_string_literal: true

module Masterfiles
  module Calendar
    module Season
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:season, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Season'
              form.view_only!
              form.add_field :season_group_id
              form.add_field :commodity_id
              form.add_field :season_code
              form.add_field :description
              form.add_field :season_year
              form.add_field :start_date
              form.add_field :end_date
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
