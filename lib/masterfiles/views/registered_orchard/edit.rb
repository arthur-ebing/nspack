# frozen_string_literal: true

module Masterfiles
  module Farms
    module RegisteredOrchard
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:registered_orchard, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Registered Orchard'
              form.action "/masterfiles/farms/registered_orchards/#{id}"
              form.remote!
              form.method :update
              form.add_field :orchard_code
              form.add_field :cultivar_code
              form.add_field :puc_code
              form.add_field :description
              form.add_field :marketing_orchard
            end
          end

          layout
        end
      end
    end
  end
end
