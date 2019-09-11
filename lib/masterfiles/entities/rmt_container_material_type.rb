# frozen_string_literal: true

module MasterfilesApp
  class RmtContainerMaterialType < Dry::Struct
    attribute :id, Types::Integer
    attribute :rmt_container_type_id, Types::Integer
    attribute :container_material_type_code, Types::String
    attribute :description, Types::String
    attribute :tare_weight, Types::Decimal
    attribute? :active, Types::Bool
    attribute :party_role_ids, Types::Array
    attribute :container_material_owners, Types::Array
  end
end
