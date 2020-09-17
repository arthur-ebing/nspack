# frozen_string_literal: true

module RawMaterialsApp
  RmtDeliverySchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:orchard_id, :integer).filled(:int?)
    required(:cultivar_id, :integer).filled(:int?)
    optional(:rmt_delivery_destination_id, :integer).maybe(:int?)
    optional(:season_id, :integer).maybe(:int?)
    required(:farm_id, :integer).filled(:int?)
    required(:puc_id, :integer).filled(:int?)
    optional(:truck_registration_number, Types::StrippedString).maybe(:str?)
    optional(:qty_damaged_bins, :integer).maybe(:int?)
    optional(:qty_empty_bins, :integer).maybe(:int?)
    optional(:date_picked, %i[nil date]).maybe(:date?)
    required(:date_delivered, :time).maybe(:time?)
    required(:received, :bool).filled(:bool?)
    optional(:current, :bool).filled(:bool?)
    optional(:keep_open, :bool).filled(:bool?)
    optional(:auto_allocate_asset_number, :bool).filled(:bool?)
    optional(:quantity_bins_with_fruit, :integer).maybe(:int?)
    optional(:reference_number, Types::StrippedString).maybe(:str?)
  end

  RmtDeliveryReceivedAtSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:date_delivered, :time).filled(:time?)
  end
end
