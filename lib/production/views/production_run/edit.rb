# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:production_run, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Set Bin Tipping Control Data',
                                  url: "/production/runs/production_runs/#{id}/set_bin_tipping_control_data",
                                  behaviour: :popup,
                                  visible: rules[:show_bin_tipping_control_data],
                                  style: :button)

              section.add_control(control_type: :link,
                                  text: 'Set Bin Tipping Criteria',
                                  url: "/production/runs/production_runs/#{id}/set_bin_tipping_criteria",
                                  behaviour: :popup,
                                  visible: rules[:show_bin_tipping_criteria],
                                  style: :button)

              section.form do |form|
                form.caption 'Edit Production Run'
                form.action "/production/runs/production_runs/#{id}"
                form.remote!
                form.method :update
                form.row do |row|
                  row.column do |col|
                    col.add_field :packhouse_resource_id
                    col.add_field :farm_id
                    col.add_field :orchard_id
                    col.add_field :cultivar_group_id
                    col.add_field :allow_cultivar_group_mixing
                    col.add_field :allow_cultivar_mixing
                    col.add_field :run_batch_number
                  end
                  row.column do |col|
                    col.add_field :production_line_id
                    col.add_field :puc_id
                    col.add_field :season_id
                    col.add_field :cultivar_id
                    col.add_field :allow_orchard_mixing
                  end
                end
                form.row do |row|
                  row.column do |col|
                    col.add_field :product_setup_template_id
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
                    end
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
