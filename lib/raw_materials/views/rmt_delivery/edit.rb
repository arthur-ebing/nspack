# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtDelivery
      class Edit
        def self.call(id, is_update: nil, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          ui_rule = UiRules::Compiler.new(:rmt_delivery, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.form do |form|
                form.caption 'Edit Rmt Delivery'
                form.action "/raw_materials/deliveries/rmt_deliveries/#{id}"
                form.remote!
                form.method :update
                form.row do |row|
                  row.column do |col|
                    col.add_field :farm_id
                    col.add_field :puc_id
                    col.add_field :orchard_id
                    col.add_field :cultivar_id
                    col.add_field :rmt_delivery_destination_id if rules[:show_delivery_destination]
                  end

                  row.column do |col|
                    form.add_field :qty_damaged_bins if rules[:show_qty_damaged_bins]
                    form.add_field :qty_empty_bins if rules[:show_qty_empty_bins]
                    col.add_field :date_delivered
                    col.add_field :date_picked
                    form.add_field :truck_registration_number if rules[:show_truck_registration_number]
                  end
                end
              end
            end

            unless is_update
              page.section do |section|
                bin_type = nil
                if rules[:scan_rmt_bin_asset_numbers]
                  section.add_control(control_type: :link,
                                      text: 'New Rmt Bin',
                                      url: "/rmd/rmt_deliveries/rmt_bins/#{id}/new",
                                      style: :button,
                                      grid_id: 'rmt_bins_deliveries',
                                      behaviour: false)
                  bin_type = 'asset_number_'
                else
                  section.add_control(control_type: :link,
                                      text: 'New Rmt Bin',
                                      url: "/raw_materials/deliveries/rmt_deliveries/#{id}/rmt_bins/new",
                                      style: :button,
                                      grid_id: 'rmt_bins_deliveries',
                                      behaviour: :popup)
                end
                section.add_grid('rmt_bins_deliveries',
                                 "/list/#{bin_type}rmt_bins/grid?key=standard&rmt_bins.delivery_id=#{id}",
                                 caption: 'Bins')
              end
            end
          end

          layout
        end
      end
    end
  end
end
