# frozen_string_literal: true

module FinishedGoodsApp
  PalletBuildupSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:destination_pallet_number).filled(Types::StrippedString)
    required(:source_pallets).filled(:array).each(:string)
    required(:qty_cartons_to_move).maybe(:integer)
    required(:created_by).maybe(Types::StrippedString)
    optional(:completed_at).maybe(:time)
    optional(:cartons_moved).maybe(:hash)
    optional(:completed).maybe(:bool)
  end
end
