# frozen_string_literal: true

module MasterfilesApp
  CultivarSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:cultivar_group_id).filled(:integer)
    required(:cultivar_name).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:cultivar_code).maybe(Types::StrippedString)
  end
end
