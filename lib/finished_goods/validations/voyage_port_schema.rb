# frozen_string_literal: true

module FinishedGoodsApp
  VoyagePortSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:voyage_id, :integer).filled(:int?)
    required(:port_id, :integer).filled(:int?)
    required(:trans_shipment_vessel_id, :integer).maybe(:int?)
    required(:ata, :time).maybe(:time?)
    required(:atd, :time).maybe(:time?)
    required(:eta, :time).maybe(:time?)
    required(:etd, :time).maybe(:time?)
  end
end
