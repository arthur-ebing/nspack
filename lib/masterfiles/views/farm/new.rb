# frozen_string_literal: true

module Masterfiles
  module Farms
    module Farm
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:farm, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Farm'
              form.action '/masterfiles/farms/farms'
              form.remote! if remote
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
