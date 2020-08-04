# frozen_string_literal: true

module RawMaterialsApp
  RmtDeliveryCostSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:rmt_delivery_id, :integer).filled(:int?)
    required(:cost_id, :integer).filled(:int?)
    required(:amount, %i[nil decimal]).maybe(:decimal?)
  end
end
