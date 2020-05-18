# frozen_string_literal: true

module RawMaterials
  module Dispatch
    module BinLoadProduct
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:bin_load_product, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.view_only!
              form.add_field :bin_load_id
              form.add_field :qty_bins
              form.add_field :cultivar_group_id
              form.add_field :cultivar_id
              form.add_field :rmt_container_material_type_id
              form.add_field :rmt_material_owner_party_role_id
              form.add_field :farm_id
              form.add_field :puc_id
              form.add_field :orchard_id
              form.add_field :rmt_class_id
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
