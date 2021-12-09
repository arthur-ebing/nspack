# frozen_string_literal: true

module Production
  module GrowerGrading
    module GrowerGradingRebin
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:grower_grading_rebin, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Grower Grading Rebin'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :grower_grading_pool_id
                  col.add_field :rmt_class_id
                  col.add_field :rebins_quantity
                  col.add_field :gross_weight
                  col.add_field :created_by
                  col.add_field :active
                end
                row.column do |col|
                  col.add_field :grower_grading_rule_item_id
                  col.add_field :rmt_size_id
                  col.add_field :pallet_rebin
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
