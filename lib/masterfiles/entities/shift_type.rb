# frozen_string_literal: true

module MasterfilesApp
  class ShiftType < Dry::Struct
    attribute :id, Types::Integer
    attribute :plant_resource_id, Types::Integer
    attribute :employment_type_id, Types::Integer
    attribute :start_hour, Types::Integer
    attribute :end_hour, Types::Integer
    attribute :day_night_or_custom, Types::Integer
    attribute :shift_type_code, Types::String
    attribute :employment_type_code, Types::String
    attribute :plant_resource_code, Types::String
  end
end
