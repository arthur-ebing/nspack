# frozen_string_literal: true

module MasterfilesApp
  PackingMethodSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:packing_method_code, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
    required(:actual_count_reduction_factor, :decimal).filled(:decimal?)
  end
end
