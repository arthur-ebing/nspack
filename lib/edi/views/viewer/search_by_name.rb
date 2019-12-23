# frozen_string_literal: true

module Edi
  module Viewer
    module File
      class SearchByName
        def self.call(caption, notice, url)
          rules = {
            fields: { search: { required: true } },
            name: ''
          }
          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object OpenStruct.new(search: nil)
            page.add_text caption, wrapper: :h3
            page.add_notice notice
            page.form do |form|
              form.action url
              form.add_field :search
            end
          end

          layout
        end
      end
    end
  end
end
