# frozen_string_literal: true

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
              form.caption 'New Rmt Delivery'
              form.action '/raw_materials/deliveries/rmt_deliveries'
              form.remote! if remote
              form.add_field :farm_id
              form.add_field :puc_id
              form.add_field :orchard_id
              form.add_field :cultivar_id
              form.add_field :rmt_delivery_destination_id if rules[:show_delivery_destination]
              form.add_field :qty_damaged_bins if rules[:show_qty_damaged_bins]
              form.add_field :qty_empty_bins if rules[:show_qty_empty_bins]
              form.add_field :date_delivered
              form.add_field :date_picked
              form.add_field :truck_registration_number if rules[:show_truck_registration_number]
            end
          end

          layout
        end
      end
    end
  end
end
