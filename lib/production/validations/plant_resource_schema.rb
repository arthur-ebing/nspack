# frozen_string_literal: true

module ProductionApp
  PlantResourceSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    optional(:plant_resource_type_id).filled(:integer)
    # optional(:system_resource_id).maybe(:integer)
    required(:plant_resource_code).filled(Types::StrippedString)
    required(:description).filled(Types::StrippedString)
    optional(:location_id).maybe(:integer)
    optional(:represents_plant_resource_id).maybe(:integer)
    optional(:resource_properties).maybe(:hash)
  end

  PlantResourceBulkPtmSchema = Dry::Schema.Params do
    required(:no_robots).filled(:integer)
    required(:plant_resource_prefix).filled(Types::StrippedString)
    required(:starting_no).filled(:integer)
    required(:bays_per_robot).filled(:integer)
  end

  PlantResourceBulkClmSchema = Dry::Schema.Params do
    required(:no_clms).filled(:integer)
    required(:no_buttons).filled(:integer)
    required(:no_clms_per_printer).filled(:integer)
    required(:plant_resource_prefix).filled(Types::StrippedString)
    required(:starting_no).filled(:integer)
  end
end
