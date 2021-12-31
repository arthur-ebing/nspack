# frozen_string_literal: true

module DM
  module Report
    module Report
      class GridPage
        def self.call(url, caption)
          Crossbeams::Layout::Page.build({}) do |page|
            page.section do |section|
              section.fit_height!
              section.add_grid('rpt_grid', url, caption: caption)
            end
          end
        end
      end
    end
  end
end
