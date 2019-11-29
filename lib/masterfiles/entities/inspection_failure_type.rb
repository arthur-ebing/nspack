# frozen_string_literal: true

module MasterfilesApp
  class InspectionFailureType < Dry::Struct
    attribute :id, Types::Integer
    attribute :failure_type_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
end
