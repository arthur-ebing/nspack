# frozen_string_literal: true

module MasterfilesApp
  BasicPackSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:basic_pack_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:length_mm).maybe(:integer)
    required(:width_mm).maybe(:integer)
    required(:height_mm).maybe(:integer)
    required(:footprint_code).maybe(Types::StrippedString)
    optional(:standard_pack_ids).maybe(:array).maybe { each(:integer) }
    optional(:bin).filled(:bool)
  end
end
