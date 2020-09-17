# frozen_string_literal: true

module MasterfilesApp
  MasterfileVariantSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    optional(:masterfile_table).filled(Types::StrippedString)
    required(:variant_code).filled(Types::StrippedString)
    optional(:masterfile_id).filled(:integer)
  end
end
