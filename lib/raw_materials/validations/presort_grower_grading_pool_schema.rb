# frozen_string_literal: true

module RawMaterialsApp
  NewPresortGrowerGradingPoolSchema = Dry::Schema.Params do
    required(:maf_lot_number).filled(Types::StrippedString)
  end

  EditPresortGrowerGradingPoolSchema = Dry::Schema.Params do
    required(:description).maybe(Types::StrippedString)
    required(:updated_by).maybe(Types::StrippedString)
  end

  PresortGrowerGradingPoolSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:maf_lot_number).filled(Types::StrippedString)
    optional(:description).maybe(Types::StrippedString)
    optional(:rmt_code_ids).maybe(:array).maybe { each(:integer) }
    required(:season_id).maybe(:integer)
    required(:commodity_id).filled(:integer)
    required(:farm_id).filled(:integer)
    required(:rmt_bin_count).maybe(:integer)
    required(:rmt_bin_weight).maybe(:decimal)
    optional(:pro_rata_factor).maybe(:decimal)
    optional(:completed).maybe(:bool)
    required(:created_by).maybe(Types::StrippedString)
    optional(:updated_by).maybe(Types::StrippedString)
  end
end
