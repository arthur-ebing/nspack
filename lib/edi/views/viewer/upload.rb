# frozen_string_literal: true

module Edi
  module Viewer
    module File
      class Upload
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:edi_viewer, :upload, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.multipart!
              form.action '/edi/viewer/upload'
              form.remote! if remote
              form.add_field :flow_type
              form.add_field :file_name
            end
          end

          layout
        end
      end
    end
  end
end
