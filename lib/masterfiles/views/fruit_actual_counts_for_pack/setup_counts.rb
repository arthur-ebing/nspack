# frozen_string_literal: true

module Masterfiles
  module Fruit
    module FruitActualCountsForPack
      class SetupCounts
        def self.call(commodity_id: nil, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:setup_standard_and_actual_counts, :new, commodity_id: commodity_id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_text 'Setup standard and actual counts for a commodity and pack', wrapper: :h2
            page.form do |form|
              form.action '/masterfiles/fruit/setup_standard_and_actual_counts'
              form.row do |row|
                row.column do |col|
                  col.add_field :commodity_id
                end
                row.column do |col|
                  col.add_field :standard_pack_code_id
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :list_of_counts
                end
              end
            end
            # If selection made, show grid
          end
        end
      end
    end
  end
end
