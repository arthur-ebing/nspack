# frozen_string_literal: true

module RawMaterials
  module Dispatch
    module BinLoadProduct
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:bin_load_product, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form do |form|
              form.view_only!
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
              if ui_rule.form_object.shipped
                section.add_grid('rmt_bins_shipped',
                                 "/list/rmt_bins/grid?key=bin_load_product&bin_load_product_id=#{id}",
                                 caption: 'Shipped Bins on Product',
                                 height: 20)
              else
                unless ui_rule.form_object.available_bin_ids.nil_or_empty?
                  section.add_grid('rmt_bins_available',
                                   "/list/rmt_bins/grid?key=available&ids=#{ui_rule.form_object.available_bin_ids}",
                                   caption: 'Available Bins for Product',
                                   height: 20)
                end
              end
            end
          end

          layout
        end
      end
    end
  end
end
