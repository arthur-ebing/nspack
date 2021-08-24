# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class RunReports
        def self.call(id)
          disp_items = [
            { url: "/production/runs/production_runs/#{id}/packout_report_dispatched",
              text: 'Standard report',
              loading_window: true },
            { url: "/production/runs/production_runs/#{id}/detailed_packout_report_dispatched",
              text: 'Detailed report',
              loading_window: true },
            { url: "/production/runs/production_runs/#{id}/packout_report_derived_dispatched",
              text: 'Use Derived weights',
              loading_window: true },
            { url: "/production/runs/production_runs/#{id}/detailed_packout_report_derived_dispatched",
              text: 'Detailed with derived weights',
              loading_window: true }
          ]
          std_items = [
            { url: "/production/runs/production_runs/#{id}/packout_report",
              text: 'Standard report',
              loading_window: true },
            { url: "/production/runs/production_runs/#{id}/detailed_packout_report",
              text: 'Detailed report',
              loading_window: true },
            { url: "/production/runs/production_runs/#{id}/packout_report_derived",
              text: 'Use Derived weights',
              loading_window: true },
            { url: "/production/runs/production_runs/#{id}/detailed_packout_report_derived",
              text: 'Detailed with derived weights',
              loading_window: true }
          ]
          Crossbeams::Layout::Page.build({}) do |page|
            page.section do |section|
              section.half_dialog_height!
              section.add_control(control_type: :dropdown_button,
                                  text: 'Dispatched only report',
                                  items: disp_items)
              section.add_control(control_type: :dropdown_button,
                                  text: 'Packout report',
                                  items: std_items)
              section.add_control(control_type: :link,
                                  url: "/production/runs/production_runs/#{id}/carton_packout_report",
                                  text: 'Carton packout report',
                                  style: :button,
                                  loading_window: true)
            end
            page.form(&:view_only!)
          end
        end
      end
    end
  end
end
