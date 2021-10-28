# frozen_string_literal: true

module Masterfiles
  module Shipping
    module Depot
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:depot, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Depot'
              form.action "/masterfiles/shipping/depots/#{id}"
              form.remote!
              form.method :update
              form.add_field :depot_code
              form.add_field :description
              form.add_field :bin_depot
              form.add_field :city_id
              form.add_field :magisterial_district
            end
          end

          layout
        end
      end
    end
  end
end
