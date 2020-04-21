# frozen_string_literal: true

module Edi
  module Viewer
    module File
      class XML
        def self.call(flow_type, file)
          xml = ::File.read(file)

          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.form_object OpenStruct.new(search: nil)
            page.add_text flow_type.upcase, wrapper: :h3
            page.add_text ::File.basename(file)
            page.add_text xml, syntax: :xml
          end

          layout
        end
      end
    end
  end
end
