# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class AllocateTargetCustomers
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:production_run, :allocate_target_customers, id: id, form_values: form_values)
          rules   = ui_rule.compile

          grid_name = rules[:locked_allocations] ? 'production_run_allocated_target_customers_view' : 'production_run_allocated_target_customers'

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_text 'Allocate Target Customers', wrapper: :h2
            page.add_text rules[:compact_header]
            page.add_notice 'This is a view-only list of target customers' if rules[:locked_allocations]
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/production_runs',
                                  style: :back_button)
            end
            page.section do |section|
              section.fit_height!
              section.add_grid('production_run_allocated_target_customers',
                               "/list/#{grid_name}/grid?key=standard&production_run_id=#{id}",
                               caption: "Allocate Target Customers for production run #{ui_rule.form_object.production_run_code}")
            end
          end

          layout
        end
      end
    end
  end
end
