# frozen_string_literal: true

module MasterfilesApp
  WageLevelSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:wage_level, :decimal).filled(:decimal?)
    required(:description, Types::StrippedString).maybe(:str?)
  end
end
