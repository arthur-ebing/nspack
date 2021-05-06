# frozen_string_literal: true

module RawMaterialsApp
  RmtDeliverySchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:orchard_id).filled(:integer)
    required(:cultivar_id).filled(:integer)
    optional(:rmt_delivery_destination_id).maybe(:integer)
    optional(:season_id).maybe(:integer)
    required(:farm_id).filled(:integer)
    required(:puc_id).filled(:integer)
    optional(:truck_registration_number).maybe(Types::StrippedString)
    optional(:qty_damaged_bins).maybe(:integer)
    optional(:qty_empty_bins).maybe(:integer)
    optional(:date_picked).maybe(:date)
    required(:date_delivered).maybe(:time)
    required(:received).filled(:bool)
    optional(:current).filled(:bool)
    optional(:keep_open).filled(:bool)
    optional(:bin_scan_mode).maybe(:integer)
    optional(:quantity_bins_with_fruit).maybe(:integer)
    optional(:reference_number).maybe(Types::StrippedString)
  end

  RmtDeliveryReceivedAtSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:date_delivered).filled(:time)
  end
end
