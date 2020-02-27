# frozen_string_literal: true

module MasterfilesApp
  class Shift < Dry::Struct
    attribute :id, Types::Integer
    attribute :shift_type_id, Types::Integer
    attribute :shift_type_code, Types::String
    attribute :employment_type_code, Types::String
    attribute :running_hours, Types::Decimal
    attribute :start_date_time, Types::DateTime
    attribute :end_date_time, Types::DateTime
    attribute? :active, Types::Bool
  end
end
