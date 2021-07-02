# frozen_string_literal: true

module Masterfiles
  module Farms
    module Orchard
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:orchard, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Orchard'
              form.view_only!
              form.add_field :farm_id
              form.add_field :puc_id
              form.add_field :orchard_code
              form.add_field :farm_section_name
              form.add_field :farm_manager_party_role_id
              form.add_field :description
              form.add_field :active
              form.add_field :cultivar_ids
            end
          end

          layout
        end
      end
    end
  end
end
