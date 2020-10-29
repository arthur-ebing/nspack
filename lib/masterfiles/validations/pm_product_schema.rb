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
    required(:material_mass).filled(:decimal)
    required(:basic_pack_id).filled(:integer)
    required(:height_mm).filled(:integer)
  end
end
