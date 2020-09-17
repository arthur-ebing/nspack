# frozen_string_literal: true

module MasterfilesApp
  PackingMethodSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:packing_method_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:actual_count_reduction_factor).filled(:decimal)
  end
end
