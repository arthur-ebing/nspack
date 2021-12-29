# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class ShowBinTippingCriteria
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:bin_tipping_criteria, :show, production_run_id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.view_only!
              form.caption 'Bin Tipping Criteria'
              form.row do |row|
                row.column do |col|
                  # col.caption 'Bin Tipping Criteria'
                  col.add_field :farm_code
                  col.add_field :commodity_code
                  col.add_field :rmt_variety_code
                  col.add_field :rmt_size
                  col.add_field :product_class_code
                end
                row.column do |col|
                  col.add_field :season_code
                  col.add_field :actual_cold_treatment
                  col.add_field :actual_ripeness_treatment
                  col.add_field :rmt_code
                end
              end

              form.row do |row|
                row.column do |col|
                  col.add_text('Bin Tipping Control Data', wrapper: :h2, css_classes: 'mb0')
                end
              end

              form.row do |row|
                row.column do |col|
                  col.add_field :colour_percentage_label
                  col.add_field :actual_ripeness_treatment_label
                  col.add_field :rmt_size_label
                end

                row.column do |col|
                  col.add_field :actual_cold_treatment_label
                  col.add_field :product_class_label
                  col.add_field :rmt_code_label
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
