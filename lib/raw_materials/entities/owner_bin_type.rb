# frozen_string_literal: true

module RawMaterialsApp
  class OwnerBinType < Dry::Struct
    attribute :id, Types::Integer
    attribute :rmt_material_owner_party_role_id, Types::Integer
    attribute :rmt_container_material_type_id, Types::Integer
    attribute :container_material_type_code, Types::String
    attribute :owner_party_name, Types::String
  end
end
