# frozen_string_literal: true

module FinishedGoodsApp
  VoyagePortSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:voyage_id, :integer).filled(:int?)
    required(:port_id, :integer).filled(:int?)
    required(:port_type_id, :integer).filled(:int?)
    optional(:trans_shipment_vessel_id, :integer).maybe(:int?)
    optional(:ata, %i[nil date]).maybe(:date?)
    optional(:atd, %i[nil date]).maybe(:date?)
    optional(:eta, %i[nil date]).maybe(:date?)
    optional(:etd, %i[nil date]).maybe(:date?)
  end
end
