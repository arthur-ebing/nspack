# frozen_string_literal: true

module Masterfiles
  module Farms
    module FarmSection
      class New
        def self.call(id, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:farm_section, :new, farm_id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Farm Section'
              form.action "/masterfiles/farms/farm_sections/#{id}/new"
              form.remote! if remote
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
