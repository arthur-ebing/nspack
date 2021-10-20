# frozen_string_literal: true

module RawMaterialsApp
  BinSequenceSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:rmt_bin_id).filled(:integer)
    required(:farm_id).filled(:integer)
    required(:orchard_id).filled(:integer)
    required(:nett_weight).maybe(:decimal)
    required(:presort_run_lot_number).maybe(Types::StrippedString)
  end
end
