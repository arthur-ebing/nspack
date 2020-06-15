# frozen_string_literal: true

module ProductionApp
  PlantResourceSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    optional(:plant_resource_type_id, :integer).filled(:int?)
    # optional(:system_resource_id, :integer).maybe(:int?)
    required(:plant_resource_code, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).filled(:str?)
    optional(:location_id, :integer).maybe(:int?)
    optional(:resource_properties, :hash).maybe(:hash?)
  end

  PlantResourceBulkPtmSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:no_robots, :integer).filled(:int?)
    required(:plant_resource_prefix, Types::StrippedString).filled(:str?)
    required(:starting_no, :integer).filled(:int?)
    required(:bays_per_robot, :integer).filled(:int?)
  end

  PlantResourceBulkClmSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:no_clms, :integer).filled(:int?)
    required(:no_buttons, :integer).filled(:int?)
    required(:no_clms_per_printer, :integer).filled(:int?)
    required(:plant_resource_prefix, Types::StrippedString).filled(:str?)
    required(:starting_no, :integer).filled(:int?)
  end
end
