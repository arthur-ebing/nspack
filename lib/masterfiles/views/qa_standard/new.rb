# frozen_string_literal: true

module Masterfiles
  module Quality
    module QaStandard
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:qa_standard, :new, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New QA Standard'
              form.action '/masterfiles/quality/qa_standards'
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :qa_standard_name
                  col.add_field :description
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :season_id
                  col.add_field :packed_tm_group_ids
                  col.add_field :internal_standard
                end
                row.column do |col|
                  col.add_field :qa_standard_type_id
                  col.add_field :target_market_ids
                  col.add_field :applies_to_all_markets
                end
              end
            end
          end
        end
      end
    end
  end
end
