# frozen_string_literal: true

module MasterfilesApp
  RipenessCodeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:ripeness_code).filled(Types::StrippedString)
    optional(:description).maybe(Types::StrippedString)
    required(:legacy_code).maybe(Types::StrippedString)
  end
end
