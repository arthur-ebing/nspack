# frozen_string_literal: true

module ProductionApp
  MarketingOrderSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:customer_party_role_id).filled(:integer)
    required(:season_id).filled(:integer)
    required(:order_number).filled(Types::StrippedString)
    required(:order_reference).maybe(Types::StrippedString)
    required(:carton_qty_required).maybe(:decimal)
    optional(:carton_qty_produced).maybe(:decimal)
    optional(:completed).maybe(:bool)
    optional(:completed_at).maybe(:time)
  end
end
