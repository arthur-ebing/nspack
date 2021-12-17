# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtBin
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/CyclomaticComplexity,  Metrics/PerceivedComplexity
          ui_rule = UiRules::Compiler.new(:rmt_bin, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Bin'
              form.action "/raw_materials/deliveries/rmt_bins/#{id}"
              form.remote!
              form.method :update
              form.add_field :bin_asset_number
              form.add_field :rmt_class_id
              form.add_field :rmt_container_type_id unless AppConst::CR_RMT.all_delivery_bins_of_same_type?
              form.add_field :qty_bins
              form.add_field :qty_inner_bins
              form.add_field :bin_fullness
              form.add_field :nett_weight if rules[:show_nett_weight]
              form.add_field :rmt_container_material_type_id if rules[:capture_container_material] && !AppConst::CR_RMT.all_delivery_bins_of_same_type?
              form.add_field :rmt_material_owner_party_role_id if rules[:capture_container_material] && rules[:capture_container_material_owner] && !AppConst::CR_RMT.all_delivery_bins_of_same_type?
              form.add_field :bin_received_date_time if rules[:edit_bin_received_date_time]
            end
          end
        end
      end
    end
  end
end
