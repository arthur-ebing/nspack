# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class SearchByPalletNumber
        def self.call(form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:reworks_run, :search, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action '/production/reworks/reworks_runs/search_by_pallet_number'
              form.caption 'Search reworks runs by pallet number'

              form.row do |row|
                row.column do |col|
                  col.add_field :pallet_number
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
