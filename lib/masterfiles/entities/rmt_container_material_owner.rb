# frozen_string_literal: true

module MasterfilesApp
  class RmtContainerMaterialOwner < Dry::Struct
    attribute :rmt_container_material_type_id, Types::Integer
    attribute :rmt_material_owner_party_role_id, Types::Integer
    attribute :id, Types::Integer
  end
end
