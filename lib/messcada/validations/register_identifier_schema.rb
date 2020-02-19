# frozen_string_literal: true

module MesscadaApp
  RegisterIdentifierSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:device, Types::StrippedString).filled(:str?)
    required(:value, Types::StrippedString).filled(:str?)
    required(:card_reader, :integer).maybe(:int?)
  end
end
