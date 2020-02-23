# frozen_string_literal: true

module MasterfilesApp
  class LocationType < Dry::Struct
    attribute :id, Types::Integer
    attribute :location_type_code, Types::String
    attribute :short_code, Types::String
    attribute :can_be_moved, Types::Bool
    attribute :hierarchical, Types::Bool
  end
end
