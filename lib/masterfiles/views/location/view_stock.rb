# frozen_string_literal: true

module Masterfiles
  module Locations
    module Location
      class ViewStock
        def self.call(id, type, back_url:)
          ui_rule = UiRules::Compiler.new(:location, :view_stock, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
            end
            page.add_text rules[:compact_header]
            page.section do |section|
              section.add_grid('view_stock',
                               "/masterfiles/locations/locations/#{id}/get_stock/#{type}/grid",
                               height: 35,
                               caption: "Location #{type.to_s.capitalize}")
            end
          end

          layout
        end
      end
    end
  end
end
