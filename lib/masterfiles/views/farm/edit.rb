# frozen_string_literal: true

module Masterfiles
  module Farms
    module Farm
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:farm, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Farm'
              form.action "/masterfiles/farms/farms/#{id}"
              form.remote!
              form.method :update
              form.add_field :owner_party_role_id
              form.add_field :pdn_region_id
              form.add_field :farm_group_id
              form.add_field :puc_id
              form.add_field :farm_code
              form.add_field :description
            end
          end

          layout
        end
      end
    end
  end
end
