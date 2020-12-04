# frozen_string_literal: true

module MasterfilesApp
  PmProductSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:pm_subtype_id).filled(:integer)
    required(:erp_code).filled(Types::StrippedString)
    required(:product_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end

  ExtendedPmProductSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:pm_subtype_id).filled(:integer)
    required(:erp_code).filled(Types::StrippedString)
    required(:product_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:material_mass).maybe(:decimal)
    required(:basic_pack_id).maybe(:integer)
    required(:height_mm).maybe(:integer)
    optional(:gross_weight_per_unit).maybe(:decimal)
    optional(:items_per_unit).maybe(:integer)
  end

  class ExtendedPmProductContract < Dry::Validation::Contract
    params do
      optional(:id).filled(:integer)
      required(:pm_subtype_id).filled(:integer)
      required(:erp_code).filled(Types::StrippedString)
      optional(:product_code).filled(Types::StrippedString)
      required(:description).maybe(Types::StrippedString)
      required(:material_mass).maybe(:decimal)
      required(:basic_pack_id).maybe(:integer)
      required(:height_mm).maybe(:integer)
      optional(:gross_weight_per_unit).maybe(:decimal)
      optional(:items_per_unit).maybe(:integer)
    end

    rule(:gross_weight_per_unit, :items_per_unit) do
      if key?(:gross_weight_per_unit) && key?(:items_per_unit)
        base.failure 'must provide either gross_weight_per_unit or items_per_unit' if values[:gross_weight_per_unit] && values[:items_per_unit]
      end
    end
  end
end
