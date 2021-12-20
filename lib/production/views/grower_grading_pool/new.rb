# frozen_string_literal: true

module Production
  module GrowerGrading
    module GrowerGradingPool
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:grower_grading_pool, :new, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/grower_grading_pools',
                                  style: :back_button)
            end
            page.form do |form|
              form.caption 'New Grower Grading Pool'
              form.action '/production/grower_grading/grower_grading_pools'
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :pool_name
                  col.add_field :description
                  col.add_field :production_run_id
                  col.add_field :inspection_type_id
                end
                row.blank_column
              end
            end
          end
        end
      end
    end
  end
end
