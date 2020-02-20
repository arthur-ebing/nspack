# frozen_string_literal: true

module Messcada
  module Hr
    module Modules
      class Confirm
        def self.call(id, url: nil, notice: nil, button_captions: ['Submit', 'Submitting...'], remote: true)
          mod_name = DB[:mes_modules].where(id: id).get(:module_code)
          rules = { name: 'module' }

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object rules
            page.add_text mod_name, wrapper: :h2
            page.form do |form|
              form.action url
              form.remote! if remote
              form.add_notice notice, show_caption: false
              form.submit_captions(*button_captions)
            end
          end

          layout
        end
      end
    end
  end
end
