# frozen_string_literal: true

module FinishedGoodsApp
  PalletHoldoverSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:pallet_id).filled(:integer)
    required(:holdover_quantity).filled(:integer)
    required(:buildup_remarks).filled(Types::StrippedString)
    required(:completed).maybe(:bool)
  end
end
