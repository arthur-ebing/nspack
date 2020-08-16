# frozen_string_literal: true

module Masterfiles
  module Config
    module Dashboard
      class URL
        def self.call(key, url)
          ui_rule = UiRules::Compiler.new(:dashboard, :url, key: key, url: url)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.remote!
              form.view_only!
              form.add_field :url
              form.add_text 'Click on the button above to copy this link to the clipboard.'
            end
          end

          layout
        end
      end
    end
  end
end
