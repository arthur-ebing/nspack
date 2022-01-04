# frozen_string_literal: true

module RawMaterials
  module PresortGrowerGrading
    module PresortGrowerGradingBin
      class New
        def self.call(presort_grading_pool_id, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:presort_grower_grading_bin, :new, form_values: form_values, presort_grading_pool_id: presort_grading_pool_id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Presort Grower Grading Bin'
              form.action "/raw_materials/presort_grower_grading/presort_grower_grading_pools/#{presort_grading_pool_id}/presort_grower_grading_bins"
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :presort_grower_grading_pool_id
                  col.add_field :maf_lot_number
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
                end
                row.column do |col|
                  col.add_field :maf_rmt_code
                  col.add_field :maf_article_count
                  col.add_field :maf_class
                  col.add_field :rmt_class_id
                  col.add_field :maf_weight
                  col.add_field :rmt_bin_weight
                  col.add_field :maf_total_lot_weight
                end
              end
            end
          end
        end
      end
    end
  end
end
