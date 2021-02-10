# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class Confirm
        def self.call(url: nil, notice: nil, button_captions: ['Recalculate', 'Recalculating...'], remote: true)
          rules = { name: 'reworks' }

          layout = Crossbeams::Layout::Page.build(rules) do |page|
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
