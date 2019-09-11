# frozen_string_literal: true

module Masterfiles
  module Farms
    module RmtContainerMaterialType
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:rmt_container_material_type, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Rmt Container Material Type'
              form.action "/masterfiles/farms/rmt_container_material_types/#{id}"
              form.remote!
              form.method :update
              form.add_field :rmt_container_type_id
              form.add_field :container_material_type_code
              form.add_field :description
              form.add_field :tare_weight
              form.add_field :party_role_ids
            end
          end

          layout
        end
      end
    end
  end
end
