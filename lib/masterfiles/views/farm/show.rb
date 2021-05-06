# frozen_string_literal: true

module Masterfiles
  module Farms
    module Farm
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:farm, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Farm'
              form.view_only!
              form.add_field :owner_party_role_id
              form.add_field :pdn_region_id
              form.add_field :farm_group_id
              form.add_field :farm_code
              form.add_field :puc_id
              form.add_field :description
              form.add_field :location_id
              form.add_field :active
              form.add_field :pucs
              form.add_field :orchards
            end
          end

          layout
        end
      end
    end
  end
end
