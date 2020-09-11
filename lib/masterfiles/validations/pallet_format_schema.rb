# frozen_string_literal: true

module MasterfilesApp
  PalletFormatSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:description).filled(Types::StrippedString)
    required(:pallet_base_id).filled(:integer)
    required(:pallet_stack_type_id).filled(:integer)
  end
end
