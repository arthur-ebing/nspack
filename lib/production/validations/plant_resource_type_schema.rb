# frozen_string_literal: true

module ProductionApp
  PlantResourceTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:plant_resource_type_code).filled(Types::StrippedString)
    required(:description).filled(Types::StrippedString)
    # required(:system_resource).filled(:bool)
    # optional(:attribute_rules).maybe(:hash)
    # optional(:behaviour_rules).maybe(:hash)
  end
end
