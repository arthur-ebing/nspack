# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module RawMaterials
  module Deliveries
    module RmtDelivery
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:rmt_delivery, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New RMT Delivery'
              form.action '/raw_materials/deliveries/rmt_deliveries'
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :farm_id
                  col.add_field :puc_id
                  col.add_field :orchard_id
                  col.add_field :farm_section
                  col.add_field :cultivar_id
                  col.add_field :rmt_delivery_destination_id
                  col.add_field :reference_number
                  col.add_field :truck_registration_number
                  col.add_field :qty_damaged_bins
                  col.add_field :qty_empty_bins
                  col.add_field :quantity_bins_with_fruit
                end
                row.column do |col|
                  col.add_field :bin_scan_mode
                  col.add_field :current
                  col.add_field :date_picked
                  col.add_field :received
                  col.add_field :date_delivered
                  # col.add_field :delivery_tipped
                  # col.add_field :tipping_complete_date_time
                  # col.add_field :keep_open
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
# rubocop:enable Metrics/BlockLength
