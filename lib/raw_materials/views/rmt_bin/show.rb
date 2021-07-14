# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtBin
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:rmt_bin, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'RMT Bin'
              form.view_only!
              form.add_field :bin_asset_number
              form.add_field :farm_id
              form.add_field :orchard_id
              form.add_field :season_id
              form.add_field :cultivar_id
              form.add_field :rmt_class_id
              form.add_field :rmt_container_type_id
              form.add_field :qty_bins
              form.add_field :qty_inner_bins
              form.add_field :bin_fullness
              form.add_field :nett_weight if rules[:show_nett_weight]
              form.add_field :rmt_container_material_type_id if rules[:show_rmt_container_material_type_id]
              form.add_field :rmt_material_owner_party_role_id if rules[:show_rmt_material_owner_party_role_id]
              form.add_field :rmt_inner_container_type_id if rules[:show_rmt_inner_container_type_id]
              form.add_field :rmt_inner_container_material_id if rules[:show_rmt_inner_container_material_id]
              form.add_field :bin_received_date_time
              form.add_field :scrapped
              form.add_field :scrapped_at
            end
          end

          layout
        end
      end
    end
  end
end
