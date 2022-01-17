# frozen_string_literal: true

module RawMaterials
  module PresortGrowerGrading
    module PresortGrowerGradingPool
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:presort_grower_grading_pool, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Presort Grower Grading Pool'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :maf_lot_number
                  col.add_field :commodity_id
                  col.add_field :rmt_bin_count
                  col.add_field :rmt_codes
                  col.add_field :created_by
                  col.add_field :active
                end
                row.column do |col|
                  col.add_field :description
                  col.add_field :season_id
                  col.add_field :farm_id
                  col.add_field :rmt_bin_weight
                  col.add_field :updated_by
                  col.add_field :completed
                end
              end
            end
          end
        end
      end
    end
  end
end
