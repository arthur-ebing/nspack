# frozen_string_literal: true

module Masterfiles
  module Locations
    module Location
      class SelectDestination
        def self.call(id:, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:location, :select_destination, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Select as destination (Parent Location)'
              form.action "/masterfiles/locations/locations/#{id}/select_destination_node"
              form.remote! if remote
              form.add_field :id
              form.add_field :location_type_id
              form.add_field :location_long_code
              form.add_notice 'Select this location to be the parent of the next location you move?', show_caption: false, notice_type: :warning
              form.submit_captions 'Select Location', 'Selecting...'
            end
          end
        end
      end
    end
  end
end
