# frozen_string_literal: true

module Masterfiles
  module Shipping
    module Depot
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:depot, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Depot'
              form.action '/masterfiles/shipping/depots'
              form.remote! if remote
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
