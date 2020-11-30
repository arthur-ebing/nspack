# frozen_string_literal: true

module MasterfilesApp
  RmtSizeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:size_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
