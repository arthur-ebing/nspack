# frozen_string_literal: true

module MasterfilesApp
  class PersonnelIdentifier < Dry::Struct
    attribute :id, Types::Integer
    attribute :hardware_type, Types::String
    attribute :identifier, Types::String
    attribute :in_use, Types::Bool
    attribute :available_from, Types::Date
  end
end
