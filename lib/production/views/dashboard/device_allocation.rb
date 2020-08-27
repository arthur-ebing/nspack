# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class DeviceAllocation
        def self.call(device)
          plant_code = ProductionApp::ResourceRepo.new.plant_resource_code_for_system_code(device)

          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_text "Allocation for #{plant_code}", wrapper: :h2
            page.add_repeating_request "/production/dashboards/device_allocation/#{device}/detail", 120_000, ''
          end

          layout
        end
      end
    end
  end
end
