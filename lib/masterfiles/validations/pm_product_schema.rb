# frozen_string_literal: true

module MasterfilesApp
  class ExtendedPmProductContract < Dry::Validation::Contract
    if AppConst::REQUIRE_EXTENDED_PACKAGING
      params do
        optional(:id).filled(:integer)
        required(:pm_subtype_id).filled(:integer)
        required(:erp_code).filled(Types::StrippedString)
        required(:product_code).filled(Types::StrippedString)
        required(:description).maybe(Types::StrippedString)
        required(:items_per_unit_client_description).maybe(Types::StrippedString)
        required(:material_mass).maybe(:decimal)
        required(:basic_pack_id).maybe(:integer)
        required(:height_mm).maybe(:integer)
        optional(:gross_weight_per_unit).maybe(:decimal)
        optional(:items_per_unit).maybe(:integer)
      end

      rule(:gross_weight_per_unit, :items_per_unit) do
        if key?(:gross_weight_per_unit) && key?(:items_per_unit)
          base.failure "Please provide either 'Gross Weight per Unit' or 'Items per Unit'" if values[:gross_weight_per_unit] && values[:items_per_unit]
        end
      end

    else
      params do
        optional(:id).filled(:integer)
        required(:pm_subtype_id).filled(:integer)
        required(:erp_code).filled(Types::StrippedString)
        required(:product_code).maybe(Types::StrippedString)
        required(:description).maybe(Types::StrippedString)
        required(:items_per_unit_client_description).maybe(Types::StrippedString)
      end
    end
  end

  ProductCodeMinimumCompositionLevelSchema = Dry::Schema.Params do
    required(:pm_type_short_code).filled(Types::StrippedString)
    required(:basic_pack_code).filled(Types::StrippedString)
    required(:pm_subtype_short_code).filled(Types::StrippedString)
  end

  MinimumPmProductSchema = Dry::Schema.Params do
    required(:pm_subtype_id).filled(:integer)
    required(:basic_pack_id).filled(:integer)
  end

  ProductCodeMidCompositionLevelSchema = Dry::Schema.Params do
    required(:pm_type_short_code).filled(Types::StrippedString)
    required(:gross_weight_per_unit).filled(Types::StrippedString)
    required(:pm_subtype_short_code).filled(Types::StrippedString)
    required(:items_per_unit).filled(Types::StrippedString)
  end

  PmProductErpSchema = Dry::Schema.Params do
    required(:erp_code).filled(Types::StrippedString)
  end
end
