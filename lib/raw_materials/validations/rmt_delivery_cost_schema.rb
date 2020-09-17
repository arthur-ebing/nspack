# frozen_string_literal: true

module RawMaterialsApp
  RmtDeliveryCostSchema = Dry::Schema.Params do
    required(:rmt_delivery_id).filled(:integer)
    required(:cost_id).filled(:integer)
    required(:amount).maybe(:decimal)
  end
end
