# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class GossamerData
        def self.call
          Crossbeams::Layout::Page.build({}) do |page|
            page.add_text 'Gossamer Data', wrapper: :h2
            page.add_repeating_request '/production/dashboards/gossamer_data/detail', 5000, ''
          end
        end
      end
    end
  end
end
