# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class ProductionRuns
        def self.call
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_text 'Production runs', wrapper: :h2
            page.add_repeating_request '/production/dashboards/production_runs/detail', 5000, ''
          end

          layout
        end
      end
    end
  end
end
