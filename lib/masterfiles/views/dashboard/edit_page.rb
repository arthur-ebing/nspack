# frozen_string_literal: true

module Masterfiles
  module Config
    module Dashboard
      class EditPage
        def self.call(key, index) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:dashboard, :edit_page, key: key, index: index)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            # page.form_values form_values
            # page.form_errors form_errors
            page.form do |form|
              form.action "/masterfiles/config/dashboards/#{key}_#{index}/update_page"
              form.remote!
              form.method :update
              form.add_field :key
              form.add_field :description
              form.add_field :desc
              form.add_field :url
              form.add_field :parameter
              form.add_field :secs
              form.add_field :select_image
            end
          end

          layout
        end
      end
    end
  end
end
