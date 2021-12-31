# frozen_string_literal: true

module DM
  module Report
    module Report
      class GridDataPage
        def self.call(grid_data)
          Crossbeams::Layout::Page.build({}) do |page|
            page.section do |section|
              section.fit_height!
              section.add_grid('rpt_grid',
                               nil,
                               caption: grid_data[:caption],
                               cold_defs: grid_data[:col_defs],
                               row_defs: grid_data[:row_defs])
            end
          end
        end
      end
    end
  end
end
