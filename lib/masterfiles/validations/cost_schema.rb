# frozen_string_literal: true

module MasterfilesApp
  CostSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:cost_type_id, :integer).filled(:int?)
    required(:cost_code, Types::StrippedString).filled(:str?)
    required(:default_amount, %i[nil decimal]).maybe(:decimal?)
    optional(:description, Types::StrippedString).maybe(:str?)
  end
end
