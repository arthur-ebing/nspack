# frozen_string_literal: true

module Production
  module Production
    module Shift
      class Filter
        def self.call(employment_type)
          ui_rule = UiRules::Compiler.new(:shift, :filter, employment_type: employment_type)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption "#{employment_type.capitalize.gsub('_', ' ')} summary report"
              form.action "/production/shifts/summary_reports/#{employment_type}/select_contract_workers"
              form.row do |row|
                row.column do |col|
                  col.add_field :from_date
                  col.add_field :to_date
                  col.add_field :employment_type_id
                  col.add_field :employment_type
                end
                row.blank_column
              end
            end
          end
          layout
        end
      end
    end
  end
end
