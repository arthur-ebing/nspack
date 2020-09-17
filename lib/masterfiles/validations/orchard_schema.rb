# frozen_string_literal: true

module MasterfilesApp
  OrchardSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:farm_id).filled(:integer)
    required(:puc_id).maybe(:integer)
    required(:orchard_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:cultivar_ids).filled(:array).each(:integer)
  end
end
