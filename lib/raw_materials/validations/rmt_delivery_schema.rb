# frozen_string_literal: true

module RawMaterialsApp
  RmtDeliverySchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:orchard_id, :integer).filled(:int?)
    required(:cultivar_id, :integer).filled(:int?)
    required(:rmt_delivery_destination_id, :integer).filled(:int?)
    required(:season_id, :integer).filled(:int?)
    required(:farm_id, :integer).filled(:int?)
    required(:puc_id, :integer).filled(:int?)
    required(:truck_registration_number, Types::StrippedString).maybe(:str?)
    required(:qty_damaged_bins, :integer).maybe(:int?)
    required(:qty_empty_bins, :integer).maybe(:int?)
    required(:date_picked, :date).maybe(:date?)
    required(:date_delivered, :time).maybe(:time?)
  end
end
