# frozen_string_literal: true

module RawMaterials
  module Dispatch
    module BinLoadProduct
      class Allocate
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:bin_load_product, :show, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Allocate Bin'
              form.action "/raw_materials/dispatch/bin_loads/#{ui_rule.form_object.bin_load_id}"
              form.submit_captions 'Close'
              form.no_submit!
              form.row do |row|
                row.column do |col|
                  col.add_field :bin_load_id
                  col.add_field :qty_bins
                  col.add_field :cultivar_group_id
                  col.add_field :cultivar_id
                  col.add_field :rmt_container_material_type_id
                  col.add_field :rmt_material_owner_party_role_id
                end
                row.column do |col|
                  col.add_field :farm_id
                  col.add_field :puc_id
                  col.add_field :orchard_id
                  col.add_field :rmt_class_id
                end
              end
            end
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: "/raw_materials/dispatch/bin_loads/#{ui_rule.form_object.bin_load_id}",
                                  style: :back_button)
              section.add_control(control_type: :link,
                                  text: 'Scan Bins',
                                  url: "/raw_materials/dispatch/bin_load_products/#{id}/scan_bins",
                                  style: :button)
            end
            page.add_notice 'Use the checkboxes to select bins from the grid below afterwards press Save selection to allocate.'
            page.section do |section|
              section.add_grid('rmt_bins',
                               '/list/bin_loads_matching_rmt_bins/grid_multi',
                               caption: 'Available Bins for Product',
                               is_multiselect: true,
                               can_be_cleared: true,
                               multiselect_url: "/raw_materials/dispatch/bin_load_products/#{id}/allocate_multiselect",
                               multiselect_key: 'bin_load_product',
                               height: 40,
                               multiselect_params: { key: 'bin_load_product',
                                                     id: id,
                                                     bin_load_product_id: id })
            end
          end

          layout
        end
      end
    end
  end
end
