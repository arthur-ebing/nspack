# frozen_string_literal: true

module MasterfilesApp
  RmtDeliveryDestinationSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:delivery_destination_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
