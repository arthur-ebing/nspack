# frozen_string_literal: true

module ProductionApp
  class Shift < Dry::Struct
    attribute :id, Types::Integer
    attribute :shift_type_id, Types::Integer
    attribute :shift_type_code, Types::String
    attribute :employment_type_code, Types::String
    attribute :running_hours, Types::Decimal
    attribute :start_date_time, Types::DateTime
    attribute :end_date_time, Types::DateTime
    attribute :packer, Types::Bool
    attribute :status, Types::String
    attribute? :active, Types::Bool
    attribute :extended_columns, Types::Hash.optional
    attribute :foreman_party_role_id, Types::Integer
    attribute :foreman, Types::String
  end
end
