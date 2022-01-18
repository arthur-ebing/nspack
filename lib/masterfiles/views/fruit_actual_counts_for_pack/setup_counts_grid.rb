# frozen_string_literal: true

module Masterfiles
  module Fruit
    module FruitActualCountsForPack
      class SetupCountsGrid
        def self.call(form_values: nil)
          ui_rule = UiRules::Compiler.new(:setup_standard_and_actual_counts, :grid, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.add_text 'Setup standard and actual counts for a commodity and pack', wrapper: :h2
            page.form do |form|
              form.view_only!
              form.no_submit!
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
            page.section do |section|
              section.add_control control_type: :link,
                                  text: 'Select again',
                                  url: "/masterfiles/fruit/setup_standard_and_actual_counts?commodity_id=#{form_values[:commodity_id]}",
                                  style: :back_button
              section.add_notice 'Enter the standard count next to each actual count (where "Exists?" is not checked) in the grid below to generate a standard and actual count', inline_caption: true
            end
            page.section do |section|
              section.fit_height!
              section.add_grid('counts',
                               "/masterfiles/fruit/setup_standard_and_actual_counts/counts_grid?commodity_id=#{form_values[:commodity_id]}&standard_pack_code_id=#{form_values[:standard_pack_code_id]}&list_of_counts=#{form_values[:list_of_counts]}",
                               caption: 'Setup standard and actual counts for a commodity and pack')
            end
          end
        end
      end
    end
  end
end
