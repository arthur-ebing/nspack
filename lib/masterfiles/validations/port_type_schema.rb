# frozen_string_literal: true

module MasterfilesApp
  PortTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:port_type_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
