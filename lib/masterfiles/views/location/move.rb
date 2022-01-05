# frozen_string_literal: true

module Masterfiles
  module Locations
    module Location
      class Move
        def self.call(id:, destination_location_id:, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:location, :move, id: id, destination_location_id: destination_location_id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Move Location'
              form.action "/masterfiles/locations/locations/#{id}/move_node"
              form.remote! if remote
              form.add_field :id
              form.add_field :location_type_id
              form.add_field :location_long_code
              form.add_field :destination_location_id
              form.add_field :destination_node
            end
          end
        end
      end
    end
  end
end
