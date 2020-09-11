# frozen_string_literal: true

module MesscadaApp
  RegisterIdentifierSchema = Dry::Schema.Params do
    required(:device).filled(Types::StrippedString)
    required(:value).filled(Types::StrippedString)
    required(:card_reader).maybe(:integer)
  end
end
