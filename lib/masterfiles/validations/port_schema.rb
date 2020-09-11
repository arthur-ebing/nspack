# frozen_string_literal: true

module MasterfilesApp
  PortSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:port_type_ids).filled(:array).each(:integer)
    required(:voyage_type_ids).filled(:array).each(:integer)
    optional(:city_id).maybe(:integer)
    required(:port_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
