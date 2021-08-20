# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class ChangeRunCultivarDetails
        def self.call(reworks_run_type_id, attrs, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:change_run_details, :cultivar_details, reworks_run_type_id: reworks_run_type_id, attrs: attrs, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/production/reworks/reworks_run_types/change_run_cultivar/reworks_runs/new',
                                  style: :back_button)
            end
            page.add_text rules[:compact_header]
            page.form do |form|
              form.action '/production/reworks/change_run_cultivar'
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :reworks_run_type
                  col.add_field :cultivar_id
                end
                row.column do |col|
                  col.add_field :reworks_run_type_id
                  col.add_field :production_run_id
                end
              end

              form.row do |row|
                row.column do |col|
                  col.add_notice('Run will be re-executed after this change.') if rules[:labeling]
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
