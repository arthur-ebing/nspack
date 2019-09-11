# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtDelivery
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:rmt_delivery, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.section do |section|
              section.form do |form|
                # form.caption 'Rmt Delivery'
                form.view_only!
                form.row do |row|
                  row.column do |col|
                    col.add_field :farm_id
                    col.add_field :puc_id
                    col.add_field :orchard_id
                    col.add_field :cultivar_id
                    col.add_field :rmt_delivery_destination_id
                    col.add_field :qty_damaged_bins
                    col.add_field :qty_empty_bins
                  end

                  row.column do |col|
                    col.add_field :date_delivered
                    col.add_field :date_picked
                    col.add_field :truck_registration_number
                    col.add_field :delivery_tipped
                    col.add_field :season_id
                    col.add_field :tipping_complete_date_time
                    col.add_field :active
                  end
                end
              end
            end

            page.section do |section|
              section.add_grid('rmt_bins_deliveries',
                               "/list/rmt_bins_view/grid?key=standard&rmt_bins.delivery_id=#{id}",
                               caption: 'Bins')
            end
          end

          layout
        end
      end
    end
  end
end
