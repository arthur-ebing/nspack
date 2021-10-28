# frozen_string_literal: true

module RawMaterialsApp
  LocationStatusSchema = Dry::Schema.Params do
    required(:status).filled(Types::StrippedString)
  end
end
