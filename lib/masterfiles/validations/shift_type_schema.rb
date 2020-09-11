# frozen_string_literal: true

module MasterfilesApp
  ShiftTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:ph_plant_resource_id).filled(:integer)
    required(:line_plant_resource_id).filled(:integer)
    required(:employment_type_id).filled(:integer)
    required(:start_hour).filled(:integer)
    required(:end_hour).filled(:integer)
    required(:day_night_or_custom).filled(:string)

    # FIXME: Dry-update
    # rule(end_hour: [:start_hour]) do |start_hour|
    #   value(:end_hour).not_eql?(start_hour)
    # end
  end

  ShiftTypeIdsSchema = Dry::Schema.Params do
    required(:from_shift_type_id).filled(:integer)
    required(:to_shift_type_id).filled(:integer)
  end
end
