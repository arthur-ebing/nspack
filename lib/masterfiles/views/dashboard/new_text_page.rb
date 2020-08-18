# frozen_string_literal: true

module Masterfiles
  module Config
    module Dashboard
      class NewTextPage
        def self.call(key) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:dashboard, :new_text_page, key: key)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.action "/masterfiles/config/dashboards/#{key}/save_text_page"
              form.remote!
              form.row do |row|
                row.column do |col|
                  col.add_field :key
                  col.add_field :description
                  col.add_field :desc
                  col.add_field :secs
                  col.add_field :existing_text
                  col.add_text <<~HTML
                    Fill in the text as lines of colour;size;text'<br>
                    Where colour is any value from the background colour dropdown.<br>
                    and size is the font size as an integer (1 to 6).
                  HTML
                end
                row.column do |col|
                  col.add_field :text_page_key
                  col.add_field :background_colour
                  col.add_field :text
                end
              end
              # grid of :: colour, size, text with actions to delete/edit and an add button
            end
          end

          layout
        end
      end
    end
  end
end
