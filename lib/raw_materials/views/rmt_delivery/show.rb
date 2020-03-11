# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtDelivery
      class Show
        def self.call(id, back_url:) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:rmt_delivery, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.section do |section| # rubocop:disable Metrics/BlockLength
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)

              section.add_control(control_type: :link,
                                  text: 'Print Bin Barcodes',
                                  url: "/raw_materials/deliveries/rmt_deliveries/#{id}/print_bin_barcodes",
                                  visible: rules[:print_bin_barcodes],
                                  loading_window: true,
                                  style: :button)

              section.add_control(control_type: :link,
                                  text: 'Print Delivery',
                                  url: "/raw_materials/deliveries/rmt_deliveries/#{id}/print_delivery",
                                  visible: rules[:print_bin_barcodes],
                                  loading_window: true,
                                  style: :button)

              section.form do |form| # rubocop:disable Metrics/BlockLength
                form.view_only!
                form.no_submit!
                form.row do |row|
                  row.column do |col|
                    col.add_field :farm_id
                    col.add_field :puc_id
                    col.add_field :orchard_id
                    col.add_field :cultivar_id
                    col.add_field :rmt_delivery_destination_id
                    col.add_field :qty_damaged_bins
                    col.add_field :qty_empty_bins
                    col.add_field :date_delivered
                    col.add_field :date_picked
                  end

                  row.column do |col|
                    col.add_field :truck_registration_number
                    col.add_field :season_id
                    col.add_field :tipping_complete_date_time
                    col.add_field :quantity_bins_with_fruit
                    col.add_field :delivery_tipped
                    col.add_field :active
                    col.add_field :keep_open
                    col.add_field :auto_allocate_asset_number
                    col.add_field :rmt_delivery_destination_id
                  end
                end
              end
            end

            page.section do |section|
              section.add_grid('rmt_bins_deliveries',
                               "/list/rmt_bins_view/grid?key=standard&delivery_id=#{id}",
                               caption: 'Bins')
            end
          end

          layout
        end
      end
    end
  end
end
