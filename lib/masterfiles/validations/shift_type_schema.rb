# frozen_string_literal: true

module MasterfilesApp
  class ShiftTypeContract < Dry::Validation::Contract
    params do
      optional(:id).filled(:integer)
      required(:ph_plant_resource_id).filled(:integer)
      required(:line_plant_resource_id).filled(:integer)
      required(:employment_type_id).filled(:integer)
      required(:start_hour).filled(:integer)
      required(:end_hour).filled(:integer)
      required(:day_night_or_custom).filled(:string)
    end

    rule(:end_hour, :start_hour) do
      key.failure 'cannot be the same as start hour' if values[:start_hour] == values[:end_hour]
    end
  end

  ShiftTypeIdsSchema = Dry::Schema.Params do
    required(:from_shift_type_id).filled(:integer)
    required(:to_shift_type_id).filled(:integer)
  end
end
