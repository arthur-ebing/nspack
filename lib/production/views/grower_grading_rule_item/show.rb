# frozen_string_literal: true

module Production
  module GrowerGrading
    module GrowerGradingRuleItem
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:grower_grading_rule_item, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Grower Grading Rule Item'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :grower_grading_rule_id
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :commodity_id
                  col.add_field :std_fruit_size_count_id
                  col.add_field :fruit_size_reference_id
                  col.add_field :grade_id
                  col.add_field :rmt_size_id
                  col.add_field :created_by
                  col.add_field :created_at
                  col.add_field :active
                end
                row.column do |col|
                  col.add_field :marketing_variety_id
                  col.add_field :fruit_actual_counts_for_pack_id
                  col.add_field :inspection_type_id
                  col.add_field :rmt_class_id
                  col.add_field :updated_by
                  col.add_field :updated_at
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
                  col.fold_up do |fold|
                    if rules[:show_rule_item_changes_fields]
                      fold.caption 'Changes'
                      rules[:rule_item_changes_fields].each do |v|
                        fold.add_field "graded_#{v}".to_sym
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
