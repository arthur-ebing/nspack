# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class PalletizingStates
        def self.call
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_text 'Palletizing bay states', wrapper: :h2
            page.add_repeating_request '/production/dashboards/palletizing_bays/detail', 5000, ''
          end

          layout
        end
      end
    end
  end
end
