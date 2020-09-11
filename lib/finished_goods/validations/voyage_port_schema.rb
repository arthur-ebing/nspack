# frozen_string_literal: true

module FinishedGoodsApp
  VoyagePortSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:voyage_id).filled(:integer)
    required(:port_id).filled(:integer)
    required(:port_type_id).filled(:integer)
    optional(:trans_shipment_vessel_id).maybe(:integer)
    optional(:ata).maybe(:date)
    optional(:atd).maybe(:date)
    optional(:eta).maybe(:date)
    optional(:etd).maybe(:date)
  end
end
