# frozen_string_literal: true

module MasterfilesApp
  RmtVariantSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:cultivar_id).filled(:integer)
    required(:rmt_variant_code).filled(Types::StrippedString)
    optional(:description).maybe(Types::StrippedString)
  end
end
