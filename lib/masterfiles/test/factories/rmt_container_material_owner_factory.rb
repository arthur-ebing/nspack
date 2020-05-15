# frozen_string_literal: true

module MasterfilesApp
  module RmtContainerMaterialOwnerFactory
    def create_rmt_container_material_owner(opts = {})
      rmt_container_material_type_id = create_rmt_container_material_type
      party_role_id = create_party_role

      default = {
        rmt_container_material_type_id: rmt_container_material_type_id,
        rmt_material_owner_party_role_id: party_role_id
      }
      DB[:rmt_container_material_owners].insert(default.merge(opts))
    end
  end
end
