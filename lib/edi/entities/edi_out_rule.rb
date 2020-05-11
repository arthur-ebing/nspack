# frozen_string_literal: true

module EdiApp
  class EdiOutRule < Dry::Struct
    attribute :id, Types::Integer
    attribute :flow_type, Types::String
    attribute :depot_id, Types::Integer
    attribute :party_role_id, Types::Integer
    attribute :hub_address, Types::String
    attribute :directory_keys, Types::Array
    attribute? :active, Types::Bool
  end
end
