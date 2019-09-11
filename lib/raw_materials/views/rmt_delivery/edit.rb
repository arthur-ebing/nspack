# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtDelivery
      class Edit
        def self.call(id, is_update: nil, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
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
                    col.add_field :qty_damaged_bins
                    col.add_field :qty_empty_bins
                    col.add_field :date_delivered
                    col.add_field :date_picked
                    col.add_field :truck_registration_number
                  end
                end
              end
            end

            unless is_update
              page.section do |section|
                section.add_control(control_type: :link, text: 'New Rmt Bin', url: "/raw_materials/deliveries/rmt_deliveries/#{id}/rmt_bins/new", style: :button, behaviour: :popup)
                section.add_grid('rmt_bins_deliveries',
                                 "/list/rmt_bins/grid?key=standard&rmt_bins.delivery_id=#{id}",
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
