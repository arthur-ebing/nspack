# frozen_string_literal: true

module Masterfiles
  module Config
    module Dashboard
      class NewPage
        def self.call(key, mode)
          ui_rule = UiRules::Compiler.new(:dashboard, mode, key: key)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            # page.form_values form_values
            # page.form_errors form_errors
            page.form do |form|
              form.action "/masterfiles/config/dashboards/#{key}/save_page"
              form.remote!
              form.add_field :key
              form.add_field :description
              form.add_field :desc
              form.add_field :url
              form.add_field :parameter
              form.add_field :secs
              # image: choose/upload
              # text: write content
              # internal dashboards: choose and apply available params
              # external dashboards: enter URL
              # Could have new text, new image, new internal and new external actions as separate forms
            end
          end

          layout
        end
      end
    end
  end
end
