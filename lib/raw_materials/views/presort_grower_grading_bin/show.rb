# frozen_string_literal: true

module RawMaterials
  module PresortGrowerGrading
    module PresortGrowerGradingBin
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:presort_grower_grading_bin, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Presort Grower Grading Bin'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :presort_grower_grading_pool_id
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :farm_id
                  col.add_field :maf_article
                  col.add_field :maf_count
                  col.add_field :rmt_size_id
                  col.add_field :maf_colour
                  col.add_field :colour_percentage_id
                  col.add_field :maf_tipped_quantity
                  col.add_field :maf_total_lot_weight
                  col.add_field :graded
                  col.add_field :active
                end
                row.column do |col|
                  col.add_field :maf_rmt_code
                  col.add_field :maf_article_count
                  col.add_field :maf_class
                  col.add_field :rmt_class_id
                  col.add_field :maf_weight
                  col.add_field :rmt_bin_weight
                  col.add_field :adjusted_weight
                  col.add_field :created_by
                  col.add_field :updated_by
                end
              end
            end
          end
        end
      end
    end
  end
end
