# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:production_run, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Production Run'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :packhouse_resource_id
                  col.add_field :farm_id
                  col.add_field :orchard_id
                  col.add_field :cultivar_group_id
                  col.add_field :product_setup_template_id
                end
                row.column do |col|
                  col.add_field :production_line_id
                  col.add_field :puc_id
                  col.add_field :season_id
                  col.add_field :cultivar_id
                  col.add_field :allow_cultivar_group_mixing
                  col.add_field :allow_cultivar_mixing
                  col.add_field :allow_orchard_mixing
                end
              end
              form.row do |row|
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
                    fold.add_field :reconfiguring
                    fold.add_field :running
                    fold.add_field :tipping
                    fold.add_field :labeling
                    fold.add_field :closed
                    fold.add_field :setup_complete
                    fold.add_field :completed
                    fold.add_field :active
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
