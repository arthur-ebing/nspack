# frozen_string_literal: true

module Masterfiles
  module Farms
    module FarmSection
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:farm_section, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Farm Section'
              form.view_only!
              form.add_field :farm_section_name
              form.add_field :farm_manager_party_role_id
              form.add_field :description
              form.add_field :orchard_ids
            end
          end

          layout
        end
      end
    end
  end
end
