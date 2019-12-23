# frozen_string_literal: true

module Edi
  module Viewer
    module File
      class ListFiles
        def self.call(caption, url)
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.section do |section|
              section.caption = caption
              section.fit_height!
              section.hide_caption = false
              section.add_grid 'edi_file_list', url
            end
          end

          layout
        end
      end
    end
  end
end
