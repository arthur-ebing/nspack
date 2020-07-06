# frozen_string_literal: true

module RmdApp
  PalletBuildupSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:destination_pallet_number, Types::StrippedString).filled(:str?)
    required(:source_pallets, :array).filled(:array?) { each(:str?) }
    required(:qty_cartons_to_move, :integer).maybe(:int?)
    required(:created_by, Types::StrippedString).maybe(:str?)
    optional(:completed_at, %i[nil time]).maybe(:time?)
    optional(:cartons_moved, :hash).maybe(:hash?)
    optional(:completed, :bool).maybe(:bool?)
  end
end
