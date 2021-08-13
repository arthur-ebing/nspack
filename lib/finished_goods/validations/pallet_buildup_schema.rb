# frozen_string_literal: true

module FinishedGoodsApp
  class PalletBuildupContract < Dry::Validation::Contract
    params do
      optional(:id).filled(:integer)
      optional(:pallet_number).maybe(Types::StrippedString)
      required(:qty_to_move).filled(:integer)
      optional(:auto_create_destination_pallet).maybe(:bool)
      required(:p1).filled(Types::StrippedString)
      optional(:p2).maybe(Types::StrippedString)
      optional(:p3).maybe(Types::StrippedString)
      optional(:p4).maybe(Types::StrippedString)
      optional(:p5).maybe(Types::StrippedString)
      optional(:p6).maybe(Types::StrippedString)
      optional(:p7).maybe(Types::StrippedString)
      optional(:p8).maybe(Types::StrippedString)
      optional(:p9).maybe(Types::StrippedString)
      optional(:p10).maybe(Types::StrippedString)
    end

    rule(:pallet_number) do
      key.failure('must be filled') if !values[:auto_create_destination_pallet] && !values[:pallet_number]
    end
  end
end
