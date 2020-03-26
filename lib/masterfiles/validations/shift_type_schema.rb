# frozen_string_literal: true

module MasterfilesApp
  ShiftTypeSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:ph_plant_resource_id, :integer).filled(:int?)
    required(:line_plant_resource_id, :integer).maybe(:int?)
    required(:employment_type_id, :integer).filled(:int?)
    required(:start_hour, :integer).filled(:int?, gt?: 0)
    required(:end_hour, :integer).filled(:int?, gt?: 0)
    required(:day_night_or_custom, :string).filled(:str?)
  end

  ShiftTypeIdsSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:from_shift_type_id).filled(:int?)
    required(:to_shift_type_id).filled(:int?)
  end
end
