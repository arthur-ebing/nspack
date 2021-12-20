# frozen_string_literal: true

module Production
  module GrowerGrading
    module GrowerGradingPool
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:grower_grading_pool, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Grower Grading Pool'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :pool_name
                  col.add_field :production_run_code
                  col.add_field :commodity_id
                  col.add_field :cultivar_group_id
                  col.add_field :cultivar_id
                  col.add_field :bin_quantity
                  col.add_field :gross_weight
                  col.add_field :created_by
                  col.add_field :rule_applied_by
                  col.add_field :active
                end
                row.column do |col|
                  col.add_field :description
                  col.add_field :grower_grading_rule_id
                  col.add_field :season_id
                  col.add_field :farm_id
                  col.add_field :inspection_type_id
                  col.add_field :pro_rata_factor
                  col.add_field :nett_weight
                  col.add_field :updated_by
                  col.add_field :rule_applied_at
                  col.add_field :completed
                  col.add_field :rule_applied
                end
              end
              form.row do |row|
                row.column do |col|
                  col.fold_up do |fold|
                    if rules[:show_legacy_data_fields]
                      fold.caption 'Legacy Data'
                      rules[:legacy_data_fields].each do |v|
                        fold.add_field v.to_sym
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
