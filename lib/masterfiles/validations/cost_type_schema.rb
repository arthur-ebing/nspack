# frozen_string_literal: true

module MasterfilesApp
  CostTypeSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:cost_type_code, Types::StrippedString).filled(:str?)
    optional(:cost_unit, Types::StrippedString).maybe(:str?)
    optional(:description, Types::StrippedString).maybe(:str?)
  end
end
