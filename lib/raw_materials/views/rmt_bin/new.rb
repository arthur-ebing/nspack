# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtBin
      class New
        def self.call(id, form_values: nil, form_errors: nil, remote: true, is_direct_create: false)
          ui_rule = UiRules::Compiler.new(:rmt_bin, :new, delivery_id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_text rules[:compact_header]
            page.form do |form|
              form.caption 'New Bin'
              form.action is_direct_create ? "/raw_materials/deliveries/rmt_deliveries/#{id}/rmt_bins/direct_create" : "/raw_materials/deliveries/rmt_deliveries/#{id}/rmt_bins"
              form.remote! if remote
              form.add_field :rmt_container_type_id
              form.add_field :rmt_class_id
              form.add_field :qty_bins
              form.add_field :qty_inner_bins
              form.add_field :bin_fullness
              form.add_field :gross_weight
              form.add_field :rmt_container_material_type_id if rules[:capture_container_material]
              form.add_field :rmt_material_owner_party_role_id if rules[:capture_container_material] && rules[:capture_container_material_owner]
            end
          end

          layout
        end
      end
    end
  end
end
