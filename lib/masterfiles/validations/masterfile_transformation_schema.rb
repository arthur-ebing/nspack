# frozen_string_literal: true

module MasterfilesApp
  MasterfileTransformationSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:masterfile_table).filled(Types::StrippedString)
    required(:external_system).filled(Types::StrippedString)
    required(:external_code).filled(Types::StrippedString)
    required(:masterfile_id).filled(:integer)
  end
end
