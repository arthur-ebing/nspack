# frozen_string_literal: true

module MasterfilesApp
  SupplierGroupSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:supplier_group_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
