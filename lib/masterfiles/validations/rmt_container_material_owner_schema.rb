# frozen_string_literal: true

module MasterfilesApp
  RmtContainerMaterialOwnerSchema = Dry::Schema.Params do
    required(:rmt_container_material_type_id).filled(:integer)
    required(:rmt_material_owner_party_role_id).filled(:integer)
    optional(:id).filled(:integer)
  end
end
