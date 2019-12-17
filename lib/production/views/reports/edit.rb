# frozen_string_literal: true

module Production
  module Reports
    module Packout
      class Edit
        def self.call # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:packout_report, :edit)
          rules   = ui_rule.compile
          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Packout Report'
              form.action '/production/reports/aggregate_packout'
              form.row do |row|
                row.column do |col|
                  col.add_field :from_date
                  col.add_field :to_date
                  col.add_field :detail_level
                end
                row.column do |col|
                  col.add_field :spacer
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
