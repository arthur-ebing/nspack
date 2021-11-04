# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class NewWipLock
        def self.call(reworks_run_type_id, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:reworks_run, :new, form_values: form_values, reworks_run_type_id: reworks_run_type_id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New WIP Lock'
              form.action "/production/reworks/reworks_run_types/#{reworks_run_type_id}/reworks_runs/work_in_progress"
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :reworks_run_type_id
                  col.add_field :reworks_run_type
                  col.add_field :pallets_selected
                  col.add_field :context
                end
                row.blank_column
              end
            end
          end

          layout
        end
      end
    end
  end
end
