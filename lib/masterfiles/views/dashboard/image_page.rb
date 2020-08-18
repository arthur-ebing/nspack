# frozen_string_literal: true

module Masterfiles
  module Config
    module Dashboard
      class ImagePage
        def self.call(key, mode) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:dashboard, mode, key: key)
          rules   = ui_rule.compile
          action = mode == :new_image_page ? 'save' : 'update'

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.action "/masterfiles/config/dashboards/#{key}/#{action}_image_page"
              form.remote!
              form.multipart!
              form.add_field :key
              form.add_field :description
              form.add_field :desc
              form.add_field :secs
              form.add_field :select_image
              form.add_field :image_file
            end
          end

          layout
        end
      end
    end
  end
end
