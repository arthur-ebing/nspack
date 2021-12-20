# frozen_string_literal: true

module Production
  module GrowerGrading
    module GrowerGradingCarton
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:grower_grading_carton, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Grower Grading Carton'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :grower_grading_pool_id
                  col.add_field :product_resource_allocation_id
                  col.add_field :marketing_org_party_role_id
                  col.add_field :packed_tm_group_id
                  col.add_field :std_fruit_size_count_id
                  col.add_field :fruit_size_reference_id
                  col.add_field :grade_id
                  col.add_field :carton_quantity
                  col.add_field :inspected_quantity
                  col.add_field :gross_weight
                  col.add_field :created_by
                  col.add_field :active
                end
                row.column do |col|
                  col.add_field :grower_grading_rule_item_id
                  col.add_field :pm_bom_id
                  col.add_field :marketing_variety_id
                  col.add_field :target_market_id
                  col.add_field :fruit_actual_counts_for_pack_id
                  col.add_field :inventory_code_id
                  col.add_field :rmt_class_id
                  col.add_field :failed_quantity
                  col.add_field :not_inspected_quantity
                  col.add_field :nett_weight
                  col.add_field :updated_by
                  col.add_field :completed
                end
              end
              form.row do |row|
                row.column do |col|
                  col.fold_up do |fold|
                    if rules[:show_changes_fields]
                      fold.caption 'Changes Made'
                      rules[:changes_made_fields].each do |v|
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
