# frozen_string_literal: true

module Masterfiles
  module Config
    module Dashboard
      class GridPage
        def self.call
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_help_link help_type: :system, path: %i[dashboards general]
            page.section do |section|
              section.add_control control_type: :link, text: 'New Dashboard', url: '/masterfiles/config/dashboards/new', style: :button, behaviour: :popup
            end
            page.section do |section|
              section.fit_height!
              section.add_grid('dash_grid', '/masterfiles/config/dashboards/grid', caption: 'Dashboards')
            end
          end

          layout
        end
      end
    end
  end
end
