# frozen_string_literal: true

module Edi
  module Viewer
    module File
      class CSV
        def self.call(flow_type, file, upload_name: nil)
          # TODO: load rows and show in grid...
          fn = upload_name ? file.path : file
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.form_object OpenStruct.new(search: nil)
            page.add_text flow_type.upcase, wrapper: :h3
            page.section do |section|
              section.fit_height!
              section.add_grid('edi_out_csv',
                               "/edi/viewer/display_edi_file/csv_grid?file_path=#{fn}",
                               caption: "#{flow_type} - #{upload_name || file}")
            end
          end

          layout
        end
      end
    end
  end
end
