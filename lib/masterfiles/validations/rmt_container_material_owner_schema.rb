# frozen_string_literal: true

module MasterfilesApp
  RmtContainerMaterialOwnerSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:rmt_container_material_type_id, :integer).filled(:int?)
    required(:rmt_material_owner_party_role_id, :integer).filled(:int?)
    optional(:id, :integer).filled(:int?)
  end
end
