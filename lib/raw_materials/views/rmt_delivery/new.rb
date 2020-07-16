# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtDelivery
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
          ui_rule = UiRules::Compiler.new(:rmt_delivery, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Rmt Delivery'
              form.action '/raw_materials/deliveries/rmt_deliveries'
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :farm_id
                  col.add_field :puc_id
                  col.add_field :orchard_id
                  col.add_field :farm_section
                  col.add_field :cultivar_id
                  col.add_field :reference_number
                end
                row.column do |col|
                  col.add_field :rmt_delivery_destination_id if rules[:show_delivery_destination]
                  col.add_field :qty_damaged_bins if rules[:show_qty_damaged_bins]
                  col.add_field :qty_empty_bins if rules[:show_qty_empty_bins]
                  col.add_field :date_picked
                  col.add_field :intake_date
                  col.add_field :truck_registration_number if rules[:show_truck_registration_number]
                  col.add_field :current
                  col.add_field :quantity_bins_with_fruit
                  col.add_field :auto_allocate_asset_number if rules[:auto_allocate_asset_number]
                  # col.add_field :rmt_delivery_destination_id
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
