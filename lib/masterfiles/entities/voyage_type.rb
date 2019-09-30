# frozen_string_literal: true

module MasterfilesApp
  class VoyageType < Dry::Struct
    attribute :id, Types::Integer
    attribute :voyage_type_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
end
