# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class ShowStats
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:production_run, :show_stats, form_values: form_values, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_text rules[:compact_header]
            page.form do |form|
              form.view_only!
              form.remote!
              form.row do |row|
                row.column do |col|
                  col.add_table(rules[:detail_rows],
                                rules[:detail_cols],
                                pivot: true,
                                alignment: rules[:detail_alignment],
                                cell_transformers: rules[:cell_transformers],
                                top_margin: 2)
                end
                row.column do |col|
                  col.add_field :cloned_from_run_id
                  col.add_field :active_run_stage
                  col.fold_up do |fold|
                    fold.caption 'Dates'
                    fold.add_field :started_at
                    fold.add_field :closed_at
                    fold.add_field :re_executed_at
                    fold.add_field :completed_at
                  end
                  col.fold_up do |fold|
                    fold.caption 'Status'
                    fold.add_field :setup_complete
                    fold.add_field :running
                    fold.add_field :reconfiguring
                    fold.add_field :closed
                    fold.add_field :completed
                  end
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
