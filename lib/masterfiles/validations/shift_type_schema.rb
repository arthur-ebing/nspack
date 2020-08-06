# frozen_string_literal: true

module MasterfilesApp
  ShiftTypeSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:ph_plant_resource_id, :integer).filled(:int?)
    required(:line_plant_resource_id, :integer).filled(:int?)
    required(:employment_type_id, :integer).filled(:int?)
    required(:start_hour, :integer).filled(:int?)
    required(:end_hour, :integer).filled(:int?)
    required(:day_night_or_custom, :string).filled(:str?)

    rule(end_hour: [:start_hour]) do |start_hour|
      value(:end_hour).not_eql?(start_hour)
    end
  end

  ShiftTypeIdsSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:from_shift_type_id).filled(:int?)
    required(:to_shift_type_id).filled(:int?)
  end
end
