# frozen_string_literal: true

module MasterfilesApp
  class Farm < Dry::Struct
    attribute :id, Types::Integer
    attribute :owner_party_role_id, Types::Integer
    attribute :pdn_region_id, Types::Integer
    attribute :farm_group_id, Types::Integer
    attribute :farm_code, Types::String
    attribute :description, Types::String
    attribute :puc_id, Types::Integer
    attribute :farm_group_code, Types::String
    attribute :owner_party_role, Types::String
    attribute :pdn_region_production_region_code, Types::String
    attribute? :active, Types::Bool
    attribute :location_id, Types::Integer
    attribute :location_long_code, Types::String
  end
end
